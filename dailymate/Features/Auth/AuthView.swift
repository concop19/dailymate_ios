//
//  AuthView.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import ComposableArchitecture
import SwiftUI

struct AuthView: View {
  @Bindable var store: StoreOf<AuthFeature>
  @FocusState private var focusedField: Field?

  enum Field: Hashable {
    case email, password, confirmPassword
  }

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(spacing: 16) {
          MascotBanner(message: store.mode.mascotMessage)

          PaperCard { form }
            .shake(trigger: store.shakeTrigger)

          Text("DailyMate — người bạn đồng hành trong căn bếp 🍃")
            .font(.footnote)
            .foregroundStyle(Color.Ghibli.cream.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
        }
        .frame(maxWidth: 480)
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, minHeight: proxy.size.height)
      }
      .scrollIndicators(.hidden)
      .scrollDismissesKeyboard(.interactively)
    }
    .background { BackgroundView() }
    .animation(.easeInOut(duration: 0.25), value: store.mode)
    .alert($store.scope(state: \.alert, action: \.alert))
  }

  // MARK: - Form

  private var form: some View {
    VStack(alignment: .leading, spacing: 12) {
      AuthHeaderView(
        emoji: store.mode.emoji,
        title: store.mode.title,
        subtitle: store.mode.subtitle
      )
      .padding(.bottom, 8)

      GhibliTextField(
        label: "Email",
        placeholder: "hello@example.com",
        text: $store.email,
        isFocused: focusedField == .email,
        keyboardType: .emailAddress,
        textContentType: .emailAddress,
        submitLabel: store.mode == .forgot ? .send : .next
      )
      .focused($focusedField, equals: .email)
      .onSubmit { advance(from: .email) }

      if store.mode.showsPassword {
        GhibliSecureField(
          label: "Mật khẩu",
          text: $store.password,
          isRevealed: store.isPasswordVisible,
          isFocused: focusedField == .password,
          textContentType: store.mode == .register ? .newPassword : .password,
          submitLabel: store.mode == .register ? .next : .go,
          onToggleReveal: { store.send(.togglePasswordVisibilityTapped) }
        )
        .focused($focusedField, equals: .password)
        .onSubmit { advance(from: .password) }
      }

      if store.mode.showsConfirmPassword {
        GhibliSecureField(
          label: "Xác nhận mật khẩu",
          text: $store.confirmPassword,
          isRevealed: store.isPasswordVisible,
          isFocused: focusedField == .confirmPassword,
          textContentType: .newPassword,
          submitLabel: .go
        )
        .focused($focusedField, equals: .confirmPassword)
        .onSubmit { advance(from: .confirmPassword) }
      }

      if store.mode.showsForgotLink {
        AuthTextLink(title: "Quên mật khẩu?", font: .footnote) {
          store.send(.modeChanged(.forgot))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }

      GhibliPrimaryButton(
        title: store.mode.ctaTitle,
        icon: store.mode.ctaIcon,
        isLoading: store.isLoading
      ) {
        submit()
      }
      .padding(.top, 12)

      if store.mode.showsGoogle {
        OrDivider().padding(.vertical, 4)
        GoogleSignInButton {
          focusedField = nil
          store.send(.googleButtonTapped)
        }
        .disabled(store.isLoading)
      }

      AuthModeSwitchView(mode: store.mode) { store.send(.modeChanged($0)) }
        .padding(.top, 8)
    }
  }

  // MARK: - Keyboard flow

  private func advance(from field: Field) {
    switch (field, store.mode) {
    case (.email, .login), (.email, .register):
      focusedField = .password
    case (.password, .register):
      focusedField = .confirmPassword
    default:
      submit()
    }
  }

  private func submit() {
    focusedField = nil
    store.send(.submitButtonTapped)
  }
}

#Preview {
  AuthView(
    store: Store(initialState: AuthFeature.State()) {
      AuthFeature()
    }
  )
}
