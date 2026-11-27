//
//  CookingRoundButton.swift
//  dailymate
//

import SwiftUI

/// Nút tròn nền kem (quay lại, đổi chế độ xem...).
struct CookingRoundButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.Ghibli.inkDark)
                .frame(width: 48, height: 48)
                .background(CookingPalette.cardCream, in: Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(GhibliPressButtonStyle())
        .accessibilityLabel(label)
    }
}
