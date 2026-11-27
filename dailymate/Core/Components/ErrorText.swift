//
//  ErrorText.swift
//  dailymate
//

import SwiftUI

/// Dòng báo lỗi nhỏ màu đỏ, dùng chung cho mọi màn.
struct ErrorText: View {
  let text: String
  init(_ text: String) { self.text = text }

  var body: some View {
    Label(text, systemImage: "exclamationmark.circle.fill")
      .font(.caption.weight(.semibold))
      .foregroundStyle(Color.red.opacity(0.8))
      .transition(.opacity)
  }
}
