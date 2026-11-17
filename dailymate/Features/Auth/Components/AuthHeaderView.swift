//
//  AuthHeaderView.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Emoji + tiêu đề + phụ đề + đường kẻ phân cách ở đầu thẻ.
struct AuthHeaderView: View {
  let emoji: String
  let title: String
  let subtitle: String

  var body: some View {
    VStack(spacing: 6) {
      Text(emoji)
        .font(.system(size: 40))
        .accessibilityHidden(true)

      Text(title)
        .font(.system(.title, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)

      Text(subtitle)
        .font(.subheadline)
        .foregroundStyle(Color.Ghibli.inkMuted)
        .lineSpacing(4)

      Capsule()
        .fill(Color.Ghibli.straw.opacity(0.5))
        .frame(height: 1.5)
        .padding(.top, 14)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  AuthHeaderView(emoji: "🍳", title: "Chào mừng trở lại", subtitle: "Đăng nhập để tiếp tục")
    .padding()
}
