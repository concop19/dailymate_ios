//
//  OnboardingRadioRow.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Thẻ chọn dạng hàng ngang (icon + tiêu đề + mô tả + nút radio tròn)
/// dùng cho Vùng miền (Stage 2) và Chế độ ăn (Stage 3).
struct OnboardingRadioRow: View {
  let emoji: String
  let title: String
  let subtitle: String
  let isSelected: Bool
  let action: () -> Void

  private let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

  var body: some View {
    Button(action: action) {
      HStack(alignment: .center, spacing: 14) {
        Text(emoji)
          .font(.system(size: 26))
          .frame(width: 48, height: 48)
          .background(
            Color.Ghibli.straw.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
          )

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(.title3, design: .serif, weight: .bold))
            .foregroundStyle(Color.Ghibli.inkDark)

          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(Color.Ghibli.inkMuted)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        radioIndicator
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 16)
      .background(isSelected ? Color(hex: 0xFFF8EA) : Color(hex: 0xFAF6EE), in: shape)
      .overlay {
        shape.strokeBorder(
          isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.45),
          lineWidth: isSelected ? 2.2 : 1.5
        )
      }
      .shadow(color: Color.Ghibli.wood.opacity(isSelected ? 0.16 : 0), radius: 8, x: 0, y: 4)
      .contentShape(shape)
    }
    .buttonStyle(.ghibliPress)
    .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var radioIndicator: some View {
    ZStack {
      Circle()
        .fill(isSelected ? Color.Ghibli.wood : Color.clear)
        .frame(width: 26, height: 26)
        .overlay {
          Circle()
            .strokeBorder(
              isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.65),
              lineWidth: 2
            )
        }

      if isSelected {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.white)
          .transition(.scale.combined(with: .opacity))
      }
    }
  }
}

#Preview {
  VStack(spacing: 12) {
    OnboardingRadioRow(
      emoji: "🏞️",
      title: "Miền Bắc",
      subtitle: "Thanh, vừa vị — phở, bún chả, canh cua",
      isSelected: false
    ) {}

    OnboardingRadioRow(
      emoji: "🌶️",
      title: "Miền Trung",
      subtitle: "Đậm, cay nồng — bún bò, mì Quảng",
      isSelected: true
    ) {}
  }
  .padding()
  .background(Color.Ghibli.cream)
}
