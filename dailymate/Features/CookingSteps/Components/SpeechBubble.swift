//
//  SpeechBubble.swift
//  dailymate
//

import SwiftUI

/// Bong bóng thoại có đuôi nhọn phía dưới.
struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.Ghibli.inkBody)
                .frame(maxWidth: 220, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(CookingPalette.cardCream, in: .rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18).strokeBorder(CookingPalette.peachPill, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
            Triangle()
                .fill(CookingPalette.cardCream)
                .frame(width: 16, height: 9)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
