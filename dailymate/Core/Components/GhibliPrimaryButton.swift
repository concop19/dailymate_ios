//
//  GhibliPrimaryButton.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI
import UIKit

/// Nút CTA chính phong cách Ghibli phủ texture giấy, cho phép tuỳ chỉnh `title`, `icon` (Emoji hoặc SF Symbol) và `color`.
struct GhibliPrimaryButton: View {
  let title: String
  var icon: String? = nil
  var color: Color = Color.Ghibli.sky
  var borderColor: Color? = nil
  var isLoading = false
  let action: () -> Void

  private let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

  private var resolvedBorderColor: Color {
    if let borderColor {
      return borderColor
    }
    return color == Color.Ghibli.sky ? Color.Ghibli.skyDeep : color
  }

  var body: some View {
    Button(action: action) {
      ZStack {
        HStack(spacing: 8) {
          if let icon, !icon.isEmpty {
            iconView(icon)
          }

          Text(title)
            .font(.system(.title3, design: .serif, weight: .bold))
        }
        .opacity(isLoading ? 0 : 1)
        .scaleEffect(isLoading ? 0.85 : 1)

        if isLoading {
          ProgressView()
            .tint(.white)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 15)
      .background {
        color
          .overlay {
            GhibliTexture.paper.image
              .resizable()
              .scaledToFill()
              .opacity(0.4)
          }
          .clipShape(shape)
      }
      .overlay {
        shape
          .strokeBorder(resolvedBorderColor, lineWidth: 2)
          .brightness(borderColor == nil && color != Color.Ghibli.sky ? -0.12 : 0)
      }
      .shadow(color: color.opacity(0.35), radius: 8, x: 0, y: 4)
      .contentShape(shape)
    }
    .buttonStyle(.ghibliPress)
    .disabled(isLoading)
    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isLoading)
    .animation(.easeInOut(duration: 0.2), value: title)
    .animation(.easeInOut(duration: 0.2), value: icon)
  }

  @ViewBuilder
  private func iconView(_ nameOrEmoji: String) -> some View {
    if UIImage(systemName: nameOrEmoji) != nil {
      Image(systemName: nameOrEmoji)
        .font(.system(.title3, weight: .bold))
    } else {
      Text(nameOrEmoji)
        .font(.system(.title3))
    }
  }
}

typealias PrimaryButton = GhibliPrimaryButton

#Preview {
  VStack(spacing: 16) {
    GhibliPrimaryButton(title: "Đăng nhập", icon: "🍳") {}
    GhibliPrimaryButton(title: "Gợi ý món ăn", icon: "sparkles", color: Color.Ghibli.wood) {}
    GhibliPrimaryButton(title: "Đăng nhập", icon: "🍳", isLoading: true) {}
  }
  .padding()
}
