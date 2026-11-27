//
//  CookingPill.swift
//  dailymate
//

import SwiftUI

/// Nhãn bo tròn nhỏ (số bước, thời gian, phương pháp nấu).
struct CookingPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}
