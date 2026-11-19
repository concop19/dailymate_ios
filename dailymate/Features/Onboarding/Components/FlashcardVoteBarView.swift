//
//  FlashcardVoteBarView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Hàng 3 nút tròn bình chọn món ăn (Không thích / Bình thường / Yêu thích) ở Stage 4.
struct FlashcardVoteBarView: View {
  let isDisabled: Bool
  let onVote: (SwipeVote) -> Void

  var body: some View {
    HStack(alignment: .bottom, spacing: 26) {
      voteButton(
        emoji: "👎",
        label: "← Không thích",
        borderColor: Color(hex: 0x9E5A3C),
        circleSize: 70
      ) {
        onVote(.dislike)
      }

      voteButton(
        emoji: "😐",
        label: "↑ Bình thường",
        borderColor: Color(hex: 0x7D6B5D),
        circleSize: 58
      ) {
        onVote(.neutral)
      }

      voteButton(
        emoji: "😋",
        label: "Yêu thích →",
        borderColor: Color(hex: 0x4E8752),
        circleSize: 70
      ) {
        onVote(.like)
      }
    }
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.5 : 1)
  }

  private func voteButton(
    emoji: String,
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

          Text(emoji)
            .font(.system(size: circleSize * 0.44))
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
