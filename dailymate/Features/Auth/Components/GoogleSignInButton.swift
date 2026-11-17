//
//  GoogleSignInButton.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Nút "Tiếp tục với Google" viền vàng rơm.
struct GoogleSignInButton: View {
  var title = "Tiếp tục với Google"
  let action: () -> Void

  private let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Text("🌐").font(.system(size: 20))
        Text(title)
          .font(.callout)
          .foregroundStyle(Color.Ghibli.inkLabel)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 13)
      .background(Color.Ghibli.inputFill, in: shape)
      .overlay { shape.strokeBorder(Color.Ghibli.straw, lineWidth: 1.5) }
      .shadow(color: Color.Ghibli.wood.opacity(0.12), radius: 5, x: 0, y: 2)
      .contentShape(shape)
    }
    .buttonStyle(.ghibliPress)
  }
}

#Preview {
  GoogleSignInButton {}
    .padding()
}
