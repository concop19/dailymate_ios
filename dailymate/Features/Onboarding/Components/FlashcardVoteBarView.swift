//
//  FlashcardVoteBarView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Hàng 3 nút tròn bình chọn món ăn (Không thích / Bình thường / Yêu thích) ở Stage 4.
struct FlashcardVoteBarView: View {
  enum EmojiImg: String {
    case good = "icon_dish_eaten_3d"
    case balance = "icon_dish_cook_3d"
    case notGood = "icon_dish_skip_3d"
      
    var imageName: String { rawValue }
  }

  let isDisabled: Bool
  let onVote: (SwipeVote) -> Void

  var body: some View {
    HStack(alignment: .bottom, spacing: 26) {
      voteButton(
        emoji: .notGood,
        label: "",
        borderColor: Color(hex: 0x9E5A3C),
        circleSize: 80
      ) {
        onVote(.dislike)
      }

      voteButton(
        emoji: .balance,
        label: "",
        borderColor: Color(hex: 0xFFFDF8),
        circleSize: 120
      ) {
        onVote(.neutral)
      }

      voteButton(
        emoji: .good,
        label: "",
        borderColor: Color(hex: 0x4E8752),
        circleSize: 80
      ) {
        onVote(.like)
      }
    }
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.5 : 1)
  }

  private func voteButton(
    emoji: EmojiImg,
    label: String,
    borderColor: Color,
    circleSize: CGFloat,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(Color(hex: 0xFFFDF8))
            .frame(width: circleSize, height: circleSize)
            .overlay {
              Circle()
                .strokeBorder(borderColor, lineWidth: 2)
            }
            .shadow(color: borderColor.opacity(0.15), radius: 6, x: 0, y: 3)

          Image(emoji.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: circleSize * 0.56, height: circleSize * 0.56)
        }

        Text(label)
          .font(.footnote.weight(.bold))
          .foregroundStyle(borderColor)
      }
    }
    .buttonStyle(.ghibliPress)
  }
}

#Preview {
  FlashcardVoteBarView(isDisabled: false) { _ in }
    .padding()
    .background(Color.Ghibli.cream)
}
