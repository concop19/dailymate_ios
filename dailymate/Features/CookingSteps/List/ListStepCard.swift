//
//  ListStepCard.swift
//  dailymate
//

import SwiftUI

/// Thẻ một bước ở chế độ danh sách — chạm để đánh dấu xong.
struct ListStepCard: View {
    let step: CookingStepDTO
    let isDone: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(isDone ? CookingPalette.green : Color.Ghibli.wood)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                    } else {
                        Text("\(step.stepNo)")
                            .font(.subheadline.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bước \(step.stepNo)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkMuted)
                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundStyle(Color.Ghibli.inkDark)
                        .multilineTextAlignment(.leading)
                    Text(isDone ? "Đã xong · chạm để bỏ đánh dấu" : "Chạm để đánh dấu đã xong")
                        .font(.caption2)
                        .foregroundStyle(isDone ? CookingPalette.green : Color.Ghibli.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(isDone ? CookingPalette.doneFill : Color.Ghibli.cream, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isDone ? CookingPalette.green : Color.Ghibli.straw, lineWidth: isDone ? 2 : 1)
            }
        }
        .buttonStyle(GhibliPressButtonStyle())
        .accessibilityAddTraits(isDone ? .isSelected : [])
    }
}
