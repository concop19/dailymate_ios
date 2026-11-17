//
//  OrDivider.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Đường kẻ ngang có chữ "hoặc" ở giữa.
struct OrDivider: View {
  var text = "hoặc"

  var body: some View {
    HStack(spacing: 10) {
      line
      Text(text)
        .font(.footnote)
        .foregroundStyle(Color.Ghibli.inkMuted)
      line
    }
  }

  private var line: some View {
    Rectangle()
      .fill(Color.Ghibli.straw.opacity(0.5))
      .frame(height: 1)
  }
}

#Preview {
  OrDivider().padding()
}
