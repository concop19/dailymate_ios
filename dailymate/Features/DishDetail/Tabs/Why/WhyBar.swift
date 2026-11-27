//
//  WhyBar.swift
//  dailymate
//

import SwiftUI

/// Thanh ngang mỏng: nền be + phần màu theo `ratio` (0...1). Dùng cho phân tích điểm và độ phù hợp.
struct WhyBar: View {
    let ratio: CGFloat
    let color: Color
    /// `false` → thanh rỗng; chuyển sang `true` trong `withAnimation` để thanh chạy ra.
    var isAnimated: Bool = true

    static let trackColor = Color(hex: 0xE7DEC8)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Self.trackColor)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
                    .frame(width: max(0, geo.size.width * min(max(ratio, 0), 1) * (isAnimated ? 1 : 0)))
            }
        }
        .frame(height: 8)
    }
}
