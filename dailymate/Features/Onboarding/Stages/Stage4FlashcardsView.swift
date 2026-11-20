//
//  Stage4FlashcardsView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import SwiftUI

struct Stage4FlashcardsView: View {
  let store: StoreOf<Stage4FlashcardsFeature>

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header

      if store.isLoadingCards {
        loadingStateView(
          message: "Đang chọn 8 món đặc trưng hợp với vùng miền và chế độ ăn của bạn..."
        )
      } else if store.isComputingTaste {
        loadingStateView(
          message: "Đang tổng hợp bản đồ vị giác từ lựa chọn của bạn..."
        )
      } else if let currentCard = store.currentCard {
        deckContent(currentCard: currentCard)
      } else if let error = store.errorMessage {
        errorStateView(error: error)
      } else {
        Spacer()
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .safeAreaInset(edge: .bottom) { skipBar }
    .background { OnboardingBackground() }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Header

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Món nào hợp gu bạn?")
        .font(.system(.largeTitle, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .fixedSize(horizontal: false, vertical: true)

      Text("Quẹt phải nếu thích, trái nếu không, lên nếu bình thường.")
        .font(.body)
        .foregroundStyle(Color.Ghibli.inkBody)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  // MARK: - Flashcard Deck & Vote Buttons

  private func deckContent(currentCard: Flashcard) -> some View {
    VStack(spacing: 20) {
      FlashcardDeckView(
        currentCard: currentCard,
        nextCard: store.nextCard
      ) { vote in
        store.send(.voteSubmitted(vote))
      }

      if let error = store.errorMessage {
        VStack(spacing: 6) {
          OnboardingErrorText(error)
          Button("Thử gửi lại kết quả") {
            store.send(.retryComputeTasteTapped)
          }
          .font(.subheadline.weight(.bold))
          .foregroundStyle(Color.Ghibli.wood)
        }
      }

      FlashcardVoteBarView(isDisabled: store.isComputingTaste) { vote in
        store.send(.voteSubmitted(vote))
      }
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  // MARK: - Loading & Error States

  private func loadingStateView(message: String) -> some View {
    VStack(spacing: 20) {
      Spacer()
      MascotBanner(
        message: message,
        animationName: "Cute cat works",
        mascotSize: 88
      )
      ProgressView()
        .tint(Color.Ghibli.wood)
        .scaleEffect(1.2)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  private func errorStateView(error: String) -> some View {
    VStack(spacing: 16) {
      Spacer()
      MascotBanner(
        message: "Chưa tải được danh sách thẻ món ăn. Bạn thử lại hoặc dùng khẩu vị theo vùng miền nhé!",
        animationName: "cat_calico",
        mascotSize: 84
      )
      OnboardingErrorText(error)

      GhibliPrimaryButton(title: "Thử lại", color: Color.Ghibli.wood) {
        store.send(.retryFetchCardsTapped)
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Bottom Skip Link

  private var skipBar: some View {
    Button {
      store.send(.skipToRegionTasteTapped)
    } label: {
      Text("Bỏ qua, dùng khẩu vị theo vùng miền")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.Ghibli.inkBody)
        .underline()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    .disabled(store.isLoadingCards || store.isComputingTaste)
    .opacity(store.isLoadingCards || store.isComputingTaste ? 0.5 : 1)
    .background(Color.Ghibli.cream.opacity(0.95))
    .overlay(alignment: .top) {
      Rectangle().fill(Color.Ghibli.straw.opacity(0.25)).frame(height: 1)
    }
  }
}

#Preview {
  NavigationStack {
    Stage4FlashcardsView(
      store: Store(initialState: Stage4FlashcardsFeature.State(draft: OnboardingDraft())) {
        Stage4FlashcardsFeature()
      } withDependencies: {
        $0.onboardingAPIClient.fetchFlashcards = { _, _ in
          [
            Flashcard(
              dishId: "dish_1",
              title: "Cá đối kho tiêu",
              imageURL: nil,
              label: "Mặn đậm",
              tasteProfile: .default
            ),
            Flashcard(
              dishId: "dish_2",
              title: "Canh chua cá lóc",
              imageURL: nil,
              label: "Chua thanh",
              tasteProfile: .default
            ),
          ]
        }
      }
    )
  }
}
