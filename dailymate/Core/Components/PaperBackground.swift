//
//  PaperBackground.swift
//  dailymate
//

import SwiftUI

/// Nền kem giấy dùng chung (Onboarding, chi tiết món, danh sách món...).
struct PaperBackground: View {
  var body: some View {
    BackgroundView(
      texture: .paper,
      baseColor: Color(hex: 0xF3EBDD),
      overlayColor: .clear,
      imageOpacity: 0.35
    )
  }
}
