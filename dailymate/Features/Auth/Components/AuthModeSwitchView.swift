//
//  AuthModeSwitchView.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Dòng chuyển mode ở cuối thẻ: login ↔ register, forgot → login.
struct AuthModeSwitchView: View {
  let mode: AuthFeature.Mode
  let onSelect: (AuthFeature.Mode) -> Void

  var body: some View {
    HStack(spacing: 4) {
      switch mode {
      case .login:
        prompt("Chưa có tài khoản?")
        AuthTextLink(title: "Đăng ký ngay", isEmphasized: true) { onSelect(.register) }
      case .register:
        prompt("Đã có tài khoản?")
        AuthTextLink(title: "Đăng nhập", isEmphasized: true) { onSelect(.login) }
      case .forgot:
        AuthTextLink(title: "← Quay lại đăng nhập", isEmphasized: true) { onSelect(.login) }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func prompt(_ text: String) -> some View {
    Text(text)
      .font(.subheadline)
      .foregroundStyle(Color.Ghibli.inkMuted)
  }
}

#Preview {
  VStack(spacing: 16) {
    AuthModeSwitchView(mode: .login) { _ in }
    AuthModeSwitchView(mode: .register) { _ in }
    AuthModeSwitchView(mode: .forgot) { _ in }
  }
  .padding()
}
