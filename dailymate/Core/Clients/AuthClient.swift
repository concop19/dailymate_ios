//
//  AuthClient.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import AuthenticationServices
import ComposableArchitecture
import Foundation
import Supabase

typealias AuthStateChange = (event: AuthChangeEvent, session: Session?)

/// Client xử lý đăng nhập (Email/Password + Google OAuth PKCE) qua Supabase.
/// Viết thủ công (không dùng macro @DependencyClient) để tránh lỗi macro plugin.
struct AuthClient: Sendable {
  var signInWithEmail: @Sendable (_ email: String, _ password: String) async throws -> Session
  var signUpWithEmail: @Sendable (_ email: String, _ password: String) async throws -> Void
  var resetPasswordForEmail: @Sendable (_ email: String) async throws -> Void
  var signInWithGoogle: @Sendable () async throws -> Session
  var signOut: @Sendable () async throws -> Void
  var handleOpenURL: @Sendable (_ url: URL) async -> Void
  var accessToken: @Sendable () async -> String?
  var refreshSession: @Sendable () async throws -> String
  var authStateChanges: @Sendable () async -> AsyncStream<AuthStateChange>
}

enum AuthClientError: LocalizedError {
  case notImplemented(String)

  var errorDescription: String? {
    switch self {
    case let .notImplemented(method):
      "Hàm \(method) chưa được mock."
    }
  }
}

extension AuthClient: DependencyKey {
  /// URL Scheme nhận callback sau khi đăng nhập Google (PKCE).
  /// - Khai báo URL Scheme `dailymate` trong Target -> Info -> URL Types
  /// - Thêm `dailymate://auth-callback` vào Redirect URLs trên Supabase Dashboard.
  private static let redirectURL = URL(string: "dailymate://auth-callback")!
  private static let resetPasswordRedirectURL = URL(string: "dailymate://reset-password")!

  static var liveValue: AuthClient {
    @Dependency(\.supabase) var supabase

    return AuthClient(
      signInWithEmail: { email, password in
        try await supabase.auth.signIn(email: email, password: password)
      },
      signUpWithEmail: { email, password in
        _ = try await supabase.auth.signUp(email: email, password: password)
      },
      resetPasswordForEmail: { email in
        try await supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: resetPasswordRedirectURL
        )
      },
      signInWithGoogle: {
        // supabase-swift tự tạo PKCE (code_verifier & code_challenge),
        // mở ASWebAuthenticationSession, đổi auth code lấy Session và lưu vào Keychain.
        try await supabase.auth.signInWithOAuth(
          provider: .google,
          redirectTo: redirectURL
        ) { (session: ASWebAuthenticationSession) in
          session.prefersEphemeralWebBrowserSession = false
        }
      },
      signOut: {
        try await supabase.auth.signOut()
      },
      handleOpenURL: { url in
        supabase.auth.handle(url)
      },
      accessToken: {
        try? await supabase.auth.session.accessToken
      },
      refreshSession: {
        try await supabase.auth.refreshSession().accessToken
      },
      authStateChanges: {
        supabase.auth.authStateChanges
      }
      // tu kich hoat de thay doi auth sesssion 
    )
  }

  static var previewValue: AuthClient {
    AuthClient(
      signInWithEmail: { _, _ in throw AuthClientError.notImplemented("signInWithEmail") },
      signUpWithEmail: { _, _ in },
      resetPasswordForEmail: { _ in },
      signInWithGoogle: { throw AuthClientError.notImplemented("signInWithGoogle") },
      signOut: {},
      handleOpenURL: { _ in },
      accessToken: { "mock-access-token" },
      refreshSession: { "mock-refreshed-access-token" },
      authStateChanges: { AsyncStream { $0.finish() } }
    )
  }

  static var testValue: AuthClient { previewValue }
}

extension DependencyValues {
  var authClient: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }
}
