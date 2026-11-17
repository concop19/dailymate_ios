//
//  GhibliInputStyle.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Nhãn phía trên ô nhập.
struct GhibliFieldLabel: View {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(.subheadline.weight(.bold))
      .foregroundStyle(Color.Ghibli.inkLabel)
  }
}

extension View {
  /// Khung ô nhập: nền kem nhạt, bo góc 14, đổi viền khi đang focus.
  func ghibliInputContainer(isFocused: Bool = false) -> some View {
    self
      .font(.body)
      .foregroundStyle(Color.Ghibli.inkDark)
      .tint(Color.Ghibli.skyDeep)
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .background(
        isFocused ? Color.white.opacity(0.92) : Color.Ghibli.inputFill,
        in: .rect(cornerRadius: 14)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 14)
          .strokeBorder(
            isFocused ? Color.Ghibli.skyDeep : Color.Ghibli.straw,
            lineWidth: isFocused ? 2 : 1.5
          )
      }
      .animation(.easeOut(duration: 0.15), value: isFocused)
  }
}

/// Prompt (placeholder) màu vàng rơm.
func ghibliPrompt(_ text: String) -> Text {
  Text(text).foregroundStyle(Color.Ghibli.straw)
}
