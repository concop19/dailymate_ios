//
//  AuthClientTests.swift
//  dailymateTests
//
//  Created by ManhLe on 11/16/26.
//

import ComposableArchitecture
import Foundation
import Supabase
import Testing
@testable import dailymate

// MARK: - 1. Unit Tests với Mock AuthClient (Chạy nhanh bằng ⌘U, không cần mạng)

@Suite("AuthClient & AuthFeature — Mock Tests")
@MainActor
struct AuthClientMockTests {

  @Test("signUpWithEmail: gọi đúng email/password và rung thông báo success")
  func signUpSuccess() async {
    let capturedEmail = LockIsolated<String?>(nil)
    let capturedPassword = LockIsolated<String?>(nil)
    let capturedHaptic = LockIsolated<ShakeClient.NotificationType?>(nil)

    var initialState = AuthFeature.State(mode: .register)
    initialState.email = "namdexuhue@dailymate.app"
    initialState.password = "password123"
    initialState.confirmPassword = "password123"

    let store = TestStore(initialState: initialState) {
      AuthFeature()
    } withDependencies: {
      $0.authClient.signUpWithEmail = { email, password in
        capturedEmail.setValue(email)
        capturedPassword.setValue(password)
      }
      $0.shakeClient.notification = { type in
        capturedHaptic.setValue(type)
      }
    }

    await store.send(.submitButtonTapped) {
      $0.isLoading = true
    }
    await store.receive(\.signUpResponse) {
      $0.isLoading = false
    }

    #expect(capturedEmail.value == "namdexuhue@dailymate.app")
    #expect(capturedPassword.value == "password123")
    #expect(capturedHaptic.value == .success)
  }

  @Test("resetPasswordForEmail: gửi email khôi phục và hiển thị Alert thành công")
  func resetPasswordSuccess() async {
    let capturedEmail = LockIsolated<String?>(nil)

    var initialState = AuthFeature.State(mode: .forgot)
    initialState.email = "forgot@dailymate.app"

    let store = TestStore(initialState: initialState) {
      AuthFeature()
    } withDependencies: {
      $0.authClient.resetPasswordForEmail = { email in
        capturedEmail.setValue(email)
      }
    }

    await store.send(.submitButtonTapped) {
      $0.isLoading = true
    }
    await store.receive(\.resetPasswordResponse) {
      $0.isLoading = false
      $0.alert = .resetEmailSent(to: "forgot@dailymate.app")
    }

    #expect(capturedEmail.value == "forgot@dailymate.app")
  }

  @Test("signInWithEmail thất bại: tăng shakeTrigger, rung lỗi và hiện thông báo thân thiện")
  func signInFailure() async {
    struct InvalidLoginError: LocalizedError {
      var errorDescription: String? { "Invalid login credentials" }
    }

    let capturedHaptic = LockIsolated<ShakeClient.NotificationType?>(nil)

    var initialState = AuthFeature.State(mode: .login)
    initialState.email = "user@dailymate.app"
    initialState.password = "wrongpass"

    let store = TestStore(initialState: initialState) {
      AuthFeature()
    } withDependencies: {
      $0.authClient.signInWithEmail = { _, _ in
        throw InvalidLoginError()
      }
      $0.shakeClient.notification = { type in
        capturedHaptic.setValue(type)
      }
    }

    await store.send(.submitButtonTapped) {
      $0.isLoading = true
    }
    await store.receive(\.signInResponse) {
      $0.isLoading = false
      $0.shakeTrigger = 1
      $0.alert = .failure("Email hoặc mật khẩu chưa đúng.")
    }

    #expect(capturedHaptic.value == .error)
  }

  @Test("handleOpenURL & accessToken & signOut: kiểm tra trực tiếp trên AuthClient")
  func directClientMethods() async throws {
    let handledURL = LockIsolated<URL?>(nil)
    let didSignOut = LockIsolated(false)

    let client = withDependencies {
      $0.authClient.handleOpenURL = { url in handledURL.setValue(url) }
      $0.authClient.accessToken = { "jwt-token-123" }
      $0.authClient.signOut = { didSignOut.setValue(true) }
    } operation: {
      @Dependency(\.authClient) var authClient
      return authClient
    }

    let callbackURL = URL(string: "dailymate://auth-callback?code=pkce_code")!
    await client.handleOpenURL(callbackURL)
    let token = await client.accessToken()
    try await client.signOut()

    #expect(handledURL.value == callbackURL)
    #expect(token == "jwt-token-123")
    #expect(didSignOut.value == true)
  }

  @Test("authStateChanges: AppFeature cập nhật trạng thái khi stream phát sự kiện")
  func authStateChangesStream() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.authClient.authStateChanges = {
        AsyncStream { continuation in
          continuation.yield((event: .initialSession, session: nil))
          continuation.finish()
        }
      }
    }

    await store.send(.task)
    await store.receive(\.authStateChanged) {
      $0.isCheckingSession = false
      $0.isAuthenticated = false
    }
  }
}

// MARK: - 2. Live Integration Tests với Supabase thật

@Suite("AuthClient — Live Supabase Tests")
struct AuthClientLiveTests {
  // Đổi sang email/password test của bạn khi chạy live test
  private let testEmail = "test.dailymate@example.com"
  private let testPassword = "Password123!"

  @Test(
    "Live: kiểm tra lấy accessToken và lắng nghe event đầu tiên từ authStateChanges",
    .disabled("Bỏ .disabled khi muốn chạy trực tiếp với Supabase thật")
  )
  func liveSessionAndStream() async {
    let client = AuthClient.liveValue

    let token = await client.accessToken()
    print("[LiveTest] Current accessToken:", token ?? "nil")

    var receivedFirstEvent = false
    for await change in await client.authStateChanges() {
      print("[LiveTest] event:", change.event, "user:", change.session?.user.email ?? "nil")
      receivedFirstEvent = true
      break
    }
    #expect(receivedFirstEvent)
  }

  @Test(
    "Live: signInWithEmail -> accessToken -> signOut",
    .disabled("Điền tài khoản thật và bỏ .disabled để test luồng đăng nhập thật")
  )
  func liveSignInAndSignOut() async throws {
    let client = AuthClient.liveValue

    let session = try await client.signInWithEmail(testEmail, testPassword)
    #expect(session.user.email == testEmail)

    let token = await client.accessToken()
    #expect(token != nil)

    try await client.signOut()
    let tokenAfterSignOut = await client.accessToken()
    #expect(tokenAfterSignOut == nil)
  }
}
