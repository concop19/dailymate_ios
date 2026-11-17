//
//  AuthTextLink.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Link dạng text gạch chân màu xanh trời (Quên mật khẩu, Đăng ký ngay...).
struct AuthTextLink: View {
  let title: String
  var font: Font = .subheadline
  var isEmphasized = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(isEmphasized ? .system(.subheadline, design: .serif, weight: .semibold) : font)
        .foregroundStyle(Color.Ghibli.skyDeep)
        .underline()
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .contentShape(.rect)
    }
    .buttonStyle(.ghibliPress(pressedScale: 0.92, hoverScale: 1.04, verticalOffset: 1))
  }
}

#Preview {
  AuthTextLink(title: "Quên mật khẩu?") {}
}
