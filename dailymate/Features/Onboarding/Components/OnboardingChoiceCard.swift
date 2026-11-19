//
//  OnboardingChoiceCard.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Thẻ chọn (có thể kèm emoji hoặc chỉ hiển thị text) dùng cho Giới tính (Stage 1), Quốc gia (Stage 2)...
struct OnboardingChoiceCard: View {
  var emoji: String? = nil
  let title: String
  let isSelected: Bool
  let action: () -> Void

  private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

  var body: some View {
    Button(action: action) {
      VStack(spacing: 10) {
        if let emoji, !emoji.isEmpty {
          Text(emoji)
            .font(.system(size: 40))
        }
        Text(title)
          .font(.system(.title3, design: .serif, weight: .bold))
          .foregroundStyle(isSelected ? Color.Ghibli.wood : Color.Ghibli.inkDark)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, emoji == nil ? 16 : 22)
      .background(isSelected ? Color(hex: 0xFFF8EA) : Color(hex: 0xFAF6EE), in: shape)
      .overlay {
        shape.strokeBorder(
          isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.45),
          lineWidth: isSelected ? 2.5 : 1.5
        )
      }
      .shadow(color: Color.Ghibli.wood.opacity(isSelected ? 0.18 : 0), radius: 8, x: 0, y: 4)
      .contentShape(shape)
    }
    .buttonStyle(.ghibliPress)
    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

#Preview {
  VStack(spacing: 16) {
    HStack(spacing: 14) {
      OnboardingChoiceCard(title: "Nam", isSelected: true) {}
      OnboardingChoiceCard(title: "Nữ", isSelected: false) {}
    }
    HStack(spacing: 14) {
      OnboardingChoiceCard(emoji: "🇻🇳", title: "Việt Nam", isSelected: true) {}
      OnboardingChoiceCard(emoji: "🌍", title: "Nước khác", isSelected: false) {}
    }
  }
  .padding()
  .background(Color.Ghibli.cream)
}
