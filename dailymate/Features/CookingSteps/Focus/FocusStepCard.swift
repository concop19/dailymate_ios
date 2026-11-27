//
//  FocusStepCard.swift
//  dailymate
//

import SwiftUI

/// Thẻ nội dung bước hiện tại ở chế độ từng bước.
struct FocusStepCard: View {
    let step: CookingStepDTO
    let index: Int
    let total: Int
    let isDone: Bool
    let languageMismatch: Bool
    let onToggle: () -> Void

    private var instructionText: some View {
        Text(step.instruction)
            .font(.system(size: 20))
            .lineSpacing(6)
            .foregroundStyle(Color.Ghibli.inkBody)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Bước \(index + 1)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(CookingPalette.peachPill, in: Capsule())
                Text("\(index + 1) / \(total)")
                    .font(.footnote)
                    .foregroundStyle(Color.Ghibli.inkMuted)
                Spacer()
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(isDone ? CookingPalette.green : .clear)
                        Circle()
                            .strokeBorder(isDone ? CookingPalette.green : Color.Ghibli.straw, lineWidth: 2)
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .accessibilityLabel(isDone ? "Đánh dấu chưa xong" : "Đánh dấu đã xong")
            }

            // Cao theo nội dung, tối đa 220pt rồi cuộn.
            ScrollView { instructionText }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: 220)
                .fixedSize(horizontal: false, vertical: true)

            if languageMismatch {
                Text("Hướng dẫn hiện chỉ có bằng tiếng Việt.")
                    .font(.caption)
                    .foregroundStyle(CookingPalette.warning)
            }
        }
        .padding(20)
        .background(CookingPalette.cardCream.opacity(0.96), in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.Ghibli.straw.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: Color.Ghibli.wood.opacity(0.25), radius: 10, y: 4)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}
