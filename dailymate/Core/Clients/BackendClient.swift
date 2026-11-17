//
//  BackendClient.swift
//  dailymate
//
//  Created by ManhLe on 11/17/26.
//

import ComposableArchitecture
import Foundation

/// Client giao tiếp với Daily Mate Backend REST API.
/// Viết thủ công (không dùng macro @DependencyClient) để tránh lỗi macro plugin.
struct BackendClient: Sendable {
  var send: @Sendable (_ endpoint: BackendEndpoint) async throws -> Data
}

// MARK: - Typed Request Helpers

extension BackendClient {
  func request<T: Decodable>(
    _ endpoint: BackendEndpoint,
    as type: T.Type = T.self
  ) async throws -> T {
    let data = try await send(endpoint)
    return try BackendJSON.decoder.decode(T.self, from: data)
  }

  func requestVoid(_ endpoint: BackendEndpoint) async throws {
    _ = try await send(endpoint)
  }
}

// MARK: - DependencyKey

extension BackendClient: DependencyKey {
  /// Giới hạn kích thước body theo quy định backend (256 KB).
  private static let maxBodyBytes = 256 * 1024
  /// Backoff cho GET khi gặp 502/503/504 (tối đa 3 lần: 1s, 2s, 4s).
  private static let transientRetryDelays: [TimeInterval] = [1, 2, 4]
// 2 thnay nay chac chan nen bo vao cau hinh. de sau nay neu co the doi   qua remote config thi cx ko gap van de gì
  static var liveValue: BackendClient {
    @Dependency(\.appConfig) var config
    @Dependency(\.authClient) var authClient

    return makeLive(
      baseURL: config.backendURL,
      authClient: authClient,
      transport: { request in
        try await URLSession.shared.data(for: request)
      }
    )
  }

  static func makeLive(
    baseURL: URL?,
    authClient: AuthClient,
    transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse),
    sleep: @escaping @Sendable (TimeInterval) async throws -> Void = { seconds in
      try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
  ) -> BackendClient {
    BackendClient(
      send: { endpoint in
        guard let baseURL else {
          throw BackendError.missingBaseURL
        }
        if let body = endpoint.body, body.count > maxBodyBytes {
          throw BackendError.payloadTooLarge(byteCount: body.count)
        }

        let token: String?
        if endpoint.requiresAuth {
          if let current = await authClient.accessToken() {
            token = current
          } else if let refreshed = try? await authClient.refreshSession() {
            token = refreshed
          } else {
            try? await authClient.signOut()
            throw BackendError.unauthorized
          }
        } else {
          token = nil
        }

        return try await executeWithRetries(
          baseURL: baseURL,
          endpoint: endpoint,
          token: token,
          authClient: authClient,
          transport: transport,
          sleep: sleep
        )
      }
    )
  }

  static var previewValue: BackendClient {
    BackendClient(send: { _ in Data("{}".utf8) })
  }

  static var testValue: BackendClient { previewValue }
}

extension DependencyValues {
  var backendClient: BackendClient {
    get { self[BackendClient.self] }
    set { self[BackendClient.self] = newValue }
  }
}

// MARK: - Networking Implementation

private extension BackendClient {
  static func executeWithRetries(
    baseURL: URL,
    endpoint: BackendEndpoint,
    token: String?,
    authClient: AuthClient,
    transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse),
    sleep: @escaping @Sendable (TimeInterval) async throws -> Void
  ) async throws -> Data {
    var currentToken = token
    var didRefreshOn401 = false
    var transientAttempt = 0

    while true {
      let request = try buildURLRequest(
        baseURL: baseURL,
        endpoint: endpoint,
        token: currentToken
      )
      let (data, response) = try await transport(request)
      guard let http = response as? HTTPURLResponse else {
        throw BackendError.invalidResponse
      }

      // 401 -> refresh session và thử lại đúng 1 lần; nếu vẫn 401 thì đăng xuất.
      if http.statusCode == 401, endpoint.requiresAuth {
        if !didRefreshOn401, let newToken = try? await authClient.refreshSession() {
          didRefreshOn401 = true
          currentToken = newToken
          continue
        }
        try? await authClient.signOut()
        throw BackendError.unauthorized
      }

      // 502 / 503 / 504 -> chỉ retry cho GET với backoff 1s, 2s, 4s (tối đa 3 lần).
      if [502, 503, 504].contains(http.statusCode),
         endpoint.method == .get,
         transientAttempt < transientRetryDelays.count {
        let delay = transientRetryDelays[transientAttempt]
        transientAttempt += 1
        try await sleep(delay)
        continue
      }

      if (200 ..< 300).contains(http.statusCode) {
        if let envelopeError = parseSuccessFalseError(statusCode: http.statusCode, data: data, response: http) {
          throw BackendError.api(envelopeError)
        }
        return data
      }

      throw BackendError.api(parseAPIError(statusCode: http.statusCode, data: data, response: http))
    }
  }

  static func buildURLRequest(
    baseURL: URL,
    endpoint: BackendEndpoint,
    token: String?
  ) throws -> URLRequest {
    let trimmedPath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
    let endpointURL = trimmedPath.isEmpty ? baseURL : baseURL.appendingPathComponent(trimmedPath)

    guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
      throw BackendError.invalidURL
    }
    if !endpoint.queryItems.isEmpty {
      components.queryItems = (components.queryItems ?? []) + endpoint.queryItems
    }
    guard let finalURL = components.url else {
      throw BackendError.invalidURL
    }

    var request = URLRequest(url: finalURL)
    request.httpMethod = endpoint.method.rawValue
    request.timeoutInterval = endpoint.timeoutInterval
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    request.setValue(endpoint.language, forHTTPHeaderField: "Accept-Language")

    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    if let body = endpoint.body {
      request.httpBody = body
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    return request
  }

  /// Parse 5 dạng lỗi thực tế từ backend (mục 2.2 tài liệu API).
  static func parseAPIError(
    statusCode: Int,
    data: Data,
    response: HTTPURLResponse
  ) -> BackendError.APIError {
    let payload = try? JSONDecoder().decode(RawErrorPayload.self, from: data)
    let message = payload?.error ?? payload?.detail ?? "Lỗi không xác định"
    let requestId = payload?.requestId ?? response.value(forHTTPHeaderField: "X-Request-ID")
    let headerRetryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
    let retryAfter = payload?.retryAfter ?? headerRetryAfter

    return BackendError.APIError(
      statusCode: statusCode,
      message: message,
      requestId: requestId,
      retryAfter: retryAfter
    )
  }

  /// Một số endpoint (vd: /weekly-plan/ask) trả `{success: false, error}`.
  static func parseSuccessFalseError(
    statusCode: Int,
    data: Data,
    response: HTTPURLResponse
  ) -> BackendError.APIError? {
    guard let payload = try? JSONDecoder().decode(RawErrorPayload.self, from: data),
          payload.success == false else {
      return nil
    }
    return parseAPIError(statusCode: statusCode, data: data, response: response)
  }
}
