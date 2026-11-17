//
//  BackendClientTests.swift
//  dailymateTests
//
//  Created by ManhLe on 11/17/26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import dailymate

@Suite("BackendClient — Unit Tests")
struct BackendClientTests {
  private let baseURL = URL(string: "https://api.dailymate.test")!

  @Test("Đính kèm Bearer token khi requiresAuth = true và bỏ qua khi requiresAuth = false")
  func attachesAuthorizationHeader() async throws {
    let capturedHeaders = LockIsolated<[String?]>([])

    var authClient = AuthClient.previewValue
    authClient.accessToken = { "token-abc" }

    let client = BackendClient.makeLive(
      baseURL: baseURL,
      authClient: authClient,
      transport: { request in
        capturedHeaders.withValue { $0.append(request.value(forHTTPHeaderField: "Authorization")) }
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        return (Data(#"{"status":"ok"}"#.utf8), response)
      }
    )

    _ = try await client.send(.get("/api/weather", requiresAuth: true))
    _ = try await client.send(.get("/health", requiresAuth: false))

    #expect(capturedHeaders.value == ["Bearer token-abc", nil])
  }

  @Test("Gặp 401: refreshSession và retry đúng 1 lần rồi thành công")
  func refreshesTokenOn401AndRetriesOnce() async throws {
    let capturedTokens = LockIsolated<[String?]>([])
    let refreshCount = LockIsolated(0)

    var authClient = AuthClient.previewValue
    authClient.accessToken = { "expired-token" }
    authClient.refreshSession = {
      refreshCount.withValue { $0 += 1 }
      return "fresh-token"
    }

    let client = BackendClient.makeLive(
      baseURL: baseURL,
      authClient: authClient,
      transport: { request in
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        capturedTokens.withValue { $0.append(authHeader) }

        let statusCode = authHeader == "Bearer fresh-token" ? 200 : 401
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: statusCode,
          httpVersion: nil,
          headerFields: nil
        )!
        return (Data("{}".utf8), response)
      }
    )

    _ = try await client.send(.get("/api/weather"))

    #expect(refreshCount.value == 1)
    #expect(capturedTokens.value == ["Bearer expired-token", "Bearer fresh-token"])
  }

  @Test("Gặp 401 lần 2 sau khi refresh: gọi signOut và ném BackendError.unauthorized")
  func signsOutWhenRetryStillReturns401() async {
    let didSignOut = LockIsolated(false)
    let requestCount = LockIsolated(0)

    var authClient = AuthClient.previewValue
    authClient.accessToken = { "expired-token" }
    authClient.refreshSession = { "still-bad-token" }
    authClient.signOut = { didSignOut.setValue(true) }

    let client = BackendClient.makeLive(
      baseURL: baseURL,
      authClient: authClient,
      transport: { request in
        requestCount.withValue { $0 += 1 }
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 401,
          httpVersion: nil,
          headerFields: nil
        )!
        return (Data(#"{"error":"Invalid token"}"#.utf8), response)
      }
    )

    await #expect(throws: BackendError.unauthorized) {
      _ = try await client.send(.get("/api/weather"))
    }
    #expect(requestCount.value == 2)
    #expect(didSignOut.value == true)
  }

  @Test("Parse đủ 5 dạng lỗi của backend")
  func parsesAllFiveErrorFormats() async {
    let cases: [(status: Int, body: String, headers: [String: String], expectedMessage: String, expectedRequestId: String?, expectedRetryAfter: TimeInterval?)] = [
      (400, #"{"error":"Body không phải JSON hợp lệ","code":400,"request_id":"req-1"}"#, [:], "Body không phải JSON hợp lệ", "req-1", nil),
      (403, #"{"error":"Forbidden"}"#, ["X-Request-ID": "req-header"], "Forbidden", "req-header", nil),
      (429, #"{"error":"Too many requests","retry_after":60}"#, ["Retry-After": "60"], "Too many requests", nil, 60),
      (400, #"{"status":"error","detail":"action phải là eaten/skipped/rated"}"#, [:], "action phải là eaten/skipped/rated", nil, nil),
      (200, #"{"success":false,"error":"Không tìm thấy thực đơn"}"#, [:], "Không tìm thấy thực đơn", nil, nil),
    ]

    for item in cases {
      let client = BackendClient.makeLive(
        baseURL: baseURL,
        authClient: .previewValue,
        transport: { request in
          let response = HTTPURLResponse(
            url: request.url!,
            statusCode: item.status,
            httpVersion: nil,
            headerFields: item.headers
          )!
          return (Data(item.body.utf8), response)
        }
      )

      do {
        _ = try await client.send(.get("/test", requiresAuth: false))
        Issue.record("Expected BackendError.api to be thrown")
      } catch let BackendError.api(apiError) {
        #expect(apiError.statusCode == item.status)
        #expect(apiError.message == item.expectedMessage)
        #expect(apiError.requestId == item.expectedRequestId)
        #expect(apiError.retryAfter == item.expectedRetryAfter)
      } catch {
        Issue.record("Unexpected error: \(error)")
      }
    }
  }

  @Test("GET gặp 503 tự retry theo backoff 1s, 2s, 4s; POST không tự retry")
  func retriesGetOnlyOnTransient5xx() async throws {
    let getAttempts = LockIsolated(0)
    let recordedDelays = LockIsolated<[TimeInterval]>([])

    let getClient = BackendClient.makeLive(
      baseURL: baseURL,
      authClient: .previewValue,
      transport: { request in
        let attempt = getAttempts.withValue {
          $0 += 1
          return $0
        }
        let status = attempt < 3 ? 503 : 200
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data("{}".utf8), response)
      },
      sleep: { delay in
        recordedDelays.withValue { $0.append(delay) }
      }
    )

    _ = try await getClient.send(.get("/health", requiresAuth: false))
    #expect(getAttempts.value == 3)
    #expect(recordedDelays.value == [1, 2])

    let postAttempts = LockIsolated(0)
    let postClient = BackendClient.makeLive(
      baseURL: baseURL,
      authClient: .previewValue,
      transport: { request in
        postAttempts.withValue { $0 += 1 }
        let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
        return (Data(#"{"error":"Service unavailable"}"#.utf8), response)
      },
      sleep: { _ in }
    )

    let postEndpoint = try BackendEndpoint.post("/api/v1/feedback", body: ["action": "eaten"])
    await #expect(throws: BackendError.self) {
      _ = try await postClient.send(postEndpoint)
    }
    #expect(postAttempts.value == 1)
  }
}
