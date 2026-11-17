//
//  AuthFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import AuthenticationServices
import ComposableArchitecture
import Foundation

/// Màn hình xác thực: Đăng nhập / Đăng ký / Quên mật khẩu / Google OAuth.
/// Khi đăng nhập thành công, `AppFeature` nhận `authStateChanges` và tự chuyển màn hình.
@Reducer
struct AuthFeature {
  enum Mode: Equatable, Sendable {
    case login
    case register
    case forgot
  }

  @ObservableState
  struct State: Equatable {
    var mode: Mode = .login
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isPasswordVisible = false
    /// Đang gọi server — đồng thời dùng để chống double-submit.
    var isLoading = false
    /// Tăng mỗi lần lỗi để View kích hoạt hiệu ứng rung thẻ (`ShakeEffect`).
    var shakeTrigger = 0
    @Presents var alert: AlertState<Action.Alert>?
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)

    // UI
    case modeChanged(Mode)
    case togglePasswordVisibilityTapped
    case submitButtonTapped
    case googleButtonTapped

    // Effect responses
    case signInResponse(Result<Void, any Error>)
      // lay ket qua tu thang phan hoi tu api dk? ham,  va lo
    case signUpResponse(Result<Void, any Error>)
    case resetPasswordResponse(Result<Void, any Error>)
    case googleResponse(Result<Void, any Error>)

    case alert(PresentationAction<Alert>)

    enum Alert: Equatable {
      case backToLogin
    }
  }

  static let minPasswordLength = 8

  @Dependency(\.authClient) var authClient
  @Dependency(\.shakeClient) var shakeClient

  var body: some Reducer<State, Action> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case let .modeChanged(mode):
        guard mode != state.mode, !state.isLoading else { return .none }
        state.mode = mode
        state.password = ""
        state.confirmPassword = ""
        state.isPasswordVisible = false
        return selectionHaptic()

      case .togglePasswordVisibilityTapped:
        state.isPasswordVisible.toggle()
        return selectionHaptic()

      case .submitButtonTapped:
        guard !state.isLoading else { return .none }
        state.email = state.email.trimmingCharacters(in: .whitespacesAndNewlines)

        if let failure = Self.validate(state) {
          return fail(&state, alert: failure.alert)
        }

        state.isLoading = true
        let email = state.email
        let password = state.password
        let authClient = self.authClient

        switch state.mode {
        case .login:
          return perform({ _ = try await authClient.signInWithEmail(email, password) }) {
            .signInResponse($0)
          }
        case .register:
          // Verify email đang tắt → signUp trả về session, AppFeature tự chuyển màn hình.
          return perform({ try await authClient.signUpWithEmail(email, password) }) {
            .signUpResponse($0)
          }
        case .forgot:
          return perform({ try await authClient.resetPasswordForEmail(email) }) {
            .resetPasswordResponse($0)
          }
        }

      case .googleButtonTapped:
        guard !state.isLoading else { return .none }
        state.isLoading = true
        let authClient = self.authClient
        return .merge(
          impactHaptic(.light),
          perform({ _ = try await authClient.signInWithGoogle() }) { .googleResponse($0) }
        )

      case .signInResponse(.success), .signUpResponse(.success), .googleResponse(.success):
        state.isLoading = false
        return notificationHaptic(.success)

      case .resetPasswordResponse(.success):
        state.isLoading = false
        state.alert = .resetEmailSent(to: state.email)
        return notificationHaptic(.success)

      case let .googleResponse(.failure(error)) where Self.isUserCancellation(error):
        // Người dùng tự đóng trang đăng nhập Google — không coi là lỗi.
        state.isLoading = false
        return .none

      case let .signInResponse(.failure(error)),
           let .signUpResponse(.failure(error)),
           let .resetPasswordResponse(.failure(error)),
           let .googleResponse(.failure(error)):
        return fail(&state, alert: .failure(Self.friendlyMessage(for: error)))

      case .alert(.presented(.backToLogin)):
        return .send(.modeChanged(.login))

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

// MARK: - Effects helpers

private extension AuthFeature {
  /// Chạy một tác vụ auth và gửi kết quả về dưới dạng `Result`.
  func perform(
    _ operation: @escaping @Sendable () async throws -> Void,
    response: @escaping @Sendable (Result<Void, any Error>) -> Action
  ) -> Effect<Action> {
    .run { send in
      do {
        try await operation()
        await send(response(.success( () ) ) )
      } catch {
        await send(response(.failure(error)))
      }
    }
  }

  /// Lỗi chung: tắt loading, rung thẻ, rung điện thoại, hiện alert (nếu có).
  func fail(_ state: inout State, alert: AlertState<Action.Alert>?) -> Effect<Action> {
    state.isLoading = false
    state.shakeTrigger += 1
    state.alert = alert
    return notificationHaptic(.error)
  }

  func notificationHaptic(_ type: ShakeClient.NotificationType) -> Effect<Action> {
    let shakeClient = self.shakeClient
    return .run { _ in await shakeClient.notification(type) }
  }

  func impactHaptic(_ style: ShakeClient.ImpactStyle) -> Effect<Action> {
    let shakeClient = self.shakeClient
    return .run { _ in await shakeClient.impact(style) }
  }

  func selectionHaptic() -> Effect<Action> {
    let shakeClient = self.shakeClient
    return .run { _ in await shakeClient.selection() }
  }
}

// MARK: - Validation

extension AuthFeature {
  enum ValidationFailure: Equatable {
    case emptyFields
    case invalidEmail
    case passwordMismatch
    case passwordTooShort

    /// `emptyFields` chỉ rung thẻ, không hiện alert.
    var alert: AlertState<Action.Alert>? {
      switch self {
      case .emptyFields:
        return nil
      case .invalidEmail:
        return .info("Email chưa hợp lệ", "Vui lòng kiểm tra lại định dạng email (vd: hello@example.com).")
      case .passwordMismatch:
        return .info("Mật khẩu không khớp", "Mật khẩu xác nhận chưa giống mật khẩu đã nhập.")
      case .passwordTooShort:
        return .info("Mật khẩu quá ngắn", "Mật khẩu cần tối thiểu \(AuthFeature.minPasswordLength) ký tự.")
      }
    }
  }

  static func validate(_ state: State) -> ValidationFailure? {
    switch state.mode {
    case .login:
      if state.email.isEmpty || state.password.isEmpty { return .emptyFields }
    case .register:
      if state.email.isEmpty || state.password.isEmpty || state.confirmPassword.isEmpty {
        return .emptyFields
      }
    case .forgot:
      if state.email.isEmpty { return .emptyFields }
    }

    if !isValidEmail(state.email) { return .invalidEmail }

    if state.mode == .register {
      if state.password != state.confirmPassword { return .passwordMismatch }
      if state.password.count < minPasswordLength { return .passwordTooShort }
    }
    return nil
  }

  static func isValidEmail(_ email: String) -> Bool {
    email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
  }
}

// MARK: - Error mapping

extension AuthFeature {
  static func isUserCancellation(_ error: any Error) -> Bool {
    if error is CancellationError { return true }
    if let webError = error as? ASWebAuthenticationSessionError, webError.code == .canceledLogin {
      return true
    }
    return false
  }

  /// Chuyển lỗi Supabase / mạng sang thông báo thân thiện.
  static func friendlyMessage(for error: any Error) -> String {
    if error is URLError {
      return "Không thể kết nối mạng. Vui lòng kiểm tra Internet và thử lại."
    }
    let message = error.localizedDescription
    let rules: [(keyword: String, friendly: String)] = [
      ("invalid login", "Email hoặc mật khẩu chưa đúng."),
      ("already registered", "Email này đã được đăng ký. Hãy đăng nhập nhé!"),
      ("email not confirmed", "Email chưa được xác nhận. Vui lòng kiểm tra hộp thư."),
      ("rate limit", "Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút."),
      ("network", "Không thể kết nối mạng. Vui lòng kiểm tra Internet và thử lại."),
    ]
    if let match = rules.first(where: { message.localizedCaseInsensitiveContains($0.keyword) }) {
      return match.friendly
    }
    return message
  }
}

// MARK: - Alerts

extension AlertState where Action == AuthFeature.Action.Alert {
  static func info(_ title: String, _ message: String) -> Self {
    AlertState {
      TextState(title)
    } actions: {
      ButtonState(role: .cancel) { TextState("OK") }
    } message: {
      TextState(message)
    }
  }

  static func failure(_ message: String) -> Self {
    .info("Ôi, có lỗi rồi 😿", message)
  }

  static func resetEmailSent(to email: String) -> Self {
    AlertState {
      TextState("📬 Đã gửi email")
    } actions: {
      ButtonState(action: .backToLogin) { TextState("Về đăng nhập") }
    } message: {
      TextState("Kiểm tra hộp thư \(email) và bấm vào liên kết để đặt lại mật khẩu.")
    }
  }
}

//static nhận đầu vào rồi trả ra
