//
//  AllergyChipButton.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Nút chip bo góc dùng cho mục "Dị ứng / Không ăn được" ở Stage 3.
struct AllergyChipButton: View {
  let emoji: String
  let title: String
  var badge: String? = nil
  let isSelected: Bool
  let action: () -> Void

  private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Text(emoji)
          .font(.system(size: 18))

        Text(title)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(Color.Ghibli.inkDark)

        if let badge, !badge.isEmpty {
          Text(badge)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.Ghibli.wood, in: .capsule)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(isSelected ? Color(hex: 0xFFF8EA) : Color(hex: 0xFAF6EE), in: shape)
      .overlay {
        shape.strokeBorder(
          isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.45),
          lineWidth: isSelected ? 2.2 : 1.5
        )
      }
      .shadow(color: Color.Ghibli.wood.opacity(isSelected ? 0.14 : 0), radius: 6, x: 0, y: 3)
      .contentShape(shape)
    }
    .buttonStyle(.ghibliPress)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

#Preview {
  FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
    AllergyChipButton(emoji: "✅", title: "Không dị ứng gì", isSelected: true) {}
    AllergyChipButton(emoji: "🦐", title: "Hải sản", badge: "Tất cả", isSelected: true) {}
    AllergyChipButton(emoji: "🐟", title: "Cá", badge: "2", isSelected: true) {}
    AllergyChipButton(emoji: "🐄", title: "Thịt bò", isSelected: false) {}
    AllergyChipButton(emoji: "🐖", title: "Thịt heo", isSelected: false) {}
  }
  .padding()
  .background(Color.Ghibli.cream)
}
