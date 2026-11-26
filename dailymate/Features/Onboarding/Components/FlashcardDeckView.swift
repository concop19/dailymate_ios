//
//  FlashcardDeckView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import Kingfisher
import Lottie
import SwiftUI
import UIKit

/// Chồng thẻ Flashcard món ăn có Mascot Lottie trên đỉnh thẻ và hỗ trợ kéo/quẹt 3 hướng:
/// - Quẹt phải: `.like` ("Yêu thích")
/// - Quẹt trái: `.dislike` ("Không thích")
/// - Quẹt lên: `.neutral` ("Bình thường")
struct FlashcardDeckView: View {
  let currentCard: Flashcard
  let nextCard: Flashcard?
  var mascotAnimationName: String = "Cattr"
  let onVote: (SwipeVote) -> Void

  @State private var dragOffset: CGSize = .zero

  private let horizontalSwipeThreshold: CGFloat = 95
  private let verticalSwipeThreshold: CGFloat = 90

  private var activeDragVote: SwipeVote? {
    if abs(dragOffset.width) >= abs(dragOffset.height) {
      if dragOffset.width > 45 { return .like }
      if dragOffset.width < -45 { return .dislike }
    } else if dragOffset.height < -45 {
      return .neutral
    }
    return nil
  }

  var body: some View {
    VStack(spacing: 0) {
      // Mascot Lottie ngồi ngay trên đỉnh thẻ như trong stage4.jpg
     

      ZStack {
        if let nextCard {
          FlashcardItemCard(card: nextCard, activeVote: nil)
            .scaleEffect(0.96)
            .rotationEffect(.degrees(2.2))
            .offset(x: 4, y: 10)
            .opacity(0.65)
            .allowsHitTesting(false)
        }

        FlashcardItemCard(card: currentCard, activeVote: activeDragVote)
          .id(currentCard.dishId)
          .offset(dragOffset)
          .rotationEffect(.degrees(Double(dragOffset.width / 18)))
          .gesture(swipeGesture)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .opacity
          ))
      }
    }
  }

  private var swipeGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        dragOffset = value.translation
      }
      .onEnded { value in
        let dx = value.translation.width
        let dy = value.translation.height

        if abs(dx) >= abs(dy) {
          if dx > horizontalSwipeThreshold {
            triggerSwipe(.like, targetOffset: CGSize(width: 420, height: dy * 0.5))
            return
          } else if dx < -horizontalSwipeThreshold {
            triggerSwipe(.dislike, targetOffset: CGSize(width: -420, height: dy * 0.5))
            return
          }
        } else if dy < -verticalSwipeThreshold {
          triggerSwipe(.neutral, targetOffset: CGSize(width: dx * 0.4, height: -420))
          return
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
          dragOffset = .zero
        }
      }
  }

  private func triggerSwipe(_ vote: SwipeVote, targetOffset: CGSize) {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    withAnimation(.easeIn(duration: 0.16)) {
      dragOffset = targetOffset
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      dragOffset = .zero
      onVote(vote)
    }
  }
}

// MARK: - Single Card View

private struct FlashcardItemCard: View {
  let card: Flashcard
  let activeVote: SwipeVote?

  private let cardShape = RoundedRectangle(cornerRadius: 28, style: .continuous)
  private let imageShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      ZStack(alignment: .topTrailing) {
        dishImage
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
          .clipShape(imageShape)

        if let label = card.label, !label.isEmpty {
          tasteTagView(label)
            .padding(14)
        }

        if let activeVote {
          voteOverlayBadge(activeVote)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
      }

      Text(card.title)
        .font(.system(.title, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .lineLimit(2)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
    .padding(14)
    .background(Color(hex: 0xFAF5EA), in: cardShape)
    .overlay {
      cardShape.strokeBorder(Color.Ghibli.straw.opacity(0.65), lineWidth: 1.8)
    }
    .shadow(color: Color.Ghibli.wood.opacity(0.14), radius: 12, x: 0, y: 6)
  }

  @ViewBuilder
  private var dishImage: some View {
    if let url = card.imageURL {
      KFImage(url)
        .placeholder {
          imagePlaceholder
        }
        .fade(duration: 0.2)
        .resizable()
        .scaledToFill()
    } else {
      imagePlaceholder
    }
  }

  private var imagePlaceholder: some View {
    ZStack {
      Color(hex: 0xEDE4D3)
      VStack(spacing: 8) {
        Text("🍲")
          .font(.system(size: 54))
        Text(card.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color.Ghibli.inkMuted)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
      }
    }
  }

  private func tasteTagView(_ text: String) -> some View {
    let tagShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    return Text(text)
      .font(.system(.subheadline, design: .serif, weight: .bold))
      .foregroundStyle(Color.Ghibli.inkDark)
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(Color(hex: 0xFFF9EE).opacity(0.95), in: tagShape)
      .overlay {
        tagShape.strokeBorder(
          Color.Ghibli.wood,
          style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
        )
      }
      .rotationEffect(.degrees(3))
      .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
  }

  private func voteOverlayBadge(_ vote: SwipeVote) -> some View {
    let (title, color): (String, Color) = switch vote {
    case .like: ("😋 YÊU THÍCH", Color(hex: 0x4E8752))
    case .dislike: ("👎 KHÔNG THÍCH", Color(hex: 0x9E5A3C))
    case .neutral: ("😐 BÌNH THƯỜNG", Color(hex: 0x7D6B5D))
    }

    return Text(title)
      .font(.subheadline.weight(.heavy))
      .foregroundStyle(.white)
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(color.opacity(0.92), in: .capsule)
  }
}
