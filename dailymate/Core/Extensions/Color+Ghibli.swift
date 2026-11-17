//
//  Color+Ghibli.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

extension Color {
  /// Khởi tạo màu từ mã hex dạng `0xRRGGBB`.
  init(hex: UInt32, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: opacity
    )
  }

  /// Bảng màu Ghibli Handcrafted dùng chung toàn app.
  enum Ghibli {
    /// Nâu gỗ — nền gốc, màu đổ bóng ấm.
    static let wood = Color(hex: 0x8B5E3C)
    /// Kem giấy — nền thẻ (card), bong bóng thoại.
    static let cream = Color(hex: 0xF5EDDC)
    /// Lớp phủ kem lên nền gỗ.
    static let creamOverlay = Color(hex: 0xF0E6D2, opacity: 0.45)
    /// Vàng rơm — viền, divider, placeholder.
    static let straw = Color(hex: 0xC8A96E)
    /// Nền ô nhập liệu.
    static let inputFill = Color(hex: 0xFFFFF0, opacity: 0.7)

    /// Mực đậm — tiêu đề, text nhập.
    static let inkDark = Color(hex: 0x3D2B1F)
    /// Mực thân — nội dung bong bóng thoại.
    static let inkBody = Color(hex: 0x4A3728)
    /// Mực nhãn — label ô nhập.
    static let inkLabel = Color(hex: 0x5C4A38)
    /// Mực nhạt — phụ đề, text phụ.
    static let inkMuted = Color(hex: 0x8B7355)

    /// Xanh trời — nút CTA, link.
    static let sky = Color(hex: 0x60A5FA)
    /// Xanh trời đậm — viền nút CTA.
    static let skyDeep = Color(hex: 0x3B82F6)
  }
}
