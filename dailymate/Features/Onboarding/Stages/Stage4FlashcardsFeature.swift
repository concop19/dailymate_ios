//
//  Stage4FlashcardsFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

/// Stage 4 — Quẹt thẻ món ăn ("Món nào hợp gu bạn?").
/// - Khi mở màn: gọi `onboardingAPIClient.fetchFlashcards(draft, language)`.
/// - Người dùng quẹt thẻ hoặc bấm 3 nút vote (`dislike`, `neutral`, `like`), hoặc bấm "Bỏ qua".
/// - Khi hết thẻ (hoặc bấm Bỏ qua): gọi `onboardingAPIClient.computeTasteProfile(draft, language)` để lấy `TasteResult`.
@Reducer
struct Stage4FlashcardsFeature {
  @ObservableState
  struct State: Equatable {
    var draftSnapshot: OnboardingDraft
    var cards: [Flashcard]
    var votes: [String: SwipeVote]
    var currentIndex: Int
    var isLoadingCards = false
    var isComputingTaste = false
    var errorMessage: String? = nil
    var language: String = "vi"

    init(
      draft: OnboardingDraft,
      language: String = "vi"
    ) {
      self.draftSnapshot = draft
      self.cards = draft.cards
      self.votes = draft.votes
      let answeredCount = draft.cards.prefix(while: { draft.votes[$0.dishId] != nil }).count
      if !draft.cards.isEmpty && answeredCount < draft.cards.count {
        self.currentIndex = answeredCount
      } else {
        self.currentIndex = 0
      }
      self.language = language
    }

    // MARK: Derived

    var currentCard: Flashcard? {
      guard cards.indices.contains(currentIndex) else { return nil }
      return cards[currentIndex]
    }

    var nextCard: Flashcard? {
      let next = currentIndex + 1
      guard cards.indices.contains(next) else { return nil }
      return cards[next]
    }

    /// Phụ đề hiển thị trên thanh Hero: `"Thẻ 1/8"`.
    var progressDetail: String? {
      guard !cards.isEmpty else { return nil }
      let displayIndex = min(currentIndex + 1, cards.count)
      return "Thẻ \(displayIndex)/\(cards.count)"
    }
  }

  enum Action: Equatable {
    case onAppear
    case retryFetchCardsTapped
    case flashcardsLoaded(Result<[Flashcard], EquatableError>)
    case voteSubmitted(SwipeVote)
    case skipToRegionTasteTapped
    case retryComputeTasteTapped
    case tasteProfileComputed(Result<TasteResult, EquatableError>)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case completed(
        cards: [Flashcard],
        votes: [String: SwipeVote],
        tasteResult: TasteResult
      )
    }
  }

  struct EquatableError: Error, Equatable, Sendable {
    let message: String
  }

  private enum CancelID {
    case fetchCards
    case computeTaste
  }

  @Dependency(\.onboardingAPIClient) var onboardingAPIClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        guard state.cards.isEmpty, !state.isLoadingCards, !state.isComputingTaste else {
          return .none
        }
        state.isLoadingCards = true
        state.errorMessage = nil
        return fetchFlashcardsEffect(draft: state.draftSnapshot, language: state.language)

      case .retryFetchCardsTapped:
        state.isLoadingCards = true
        state.errorMessage = nil
        return fetchFlashcardsEffect(draft: state.draftSnapshot, language: state.language)

      case let .flashcardsLoaded(.success(cards)):
        state.isLoadingCards = false
        state.errorMessage = nil
        state.cards = cards
        state.votes = [:]
        state.currentIndex = 0

        if cards.isEmpty {
          state.isComputingTaste = true
          return computeTasteEffect(state: state)
        }
        return .none

      case let .flashcardsLoaded(.failure(error)):
        state.isLoadingCards = false
        state.errorMessage = error.message
        return .none

      case let .voteSubmitted(vote):
        guard !state.isComputingTaste, let card = state.currentCard else {
          return .none
        }
        state.votes[card.dishId] = vote
        state.errorMessage = nil

        if state.currentIndex + 1 < state.cards.count {
          state.currentIndex += 1
          return .none
        } else {
          state.isComputingTaste = true
          return computeTasteEffect(state: state)
        }

      case .skipToRegionTasteTapped:
        guard !state.isComputingTaste else { return .none }
        state.votes = [:]
        state.errorMessage = nil
        state.isComputingTaste = true
        return computeTasteEffect(state: state)

      case .retryComputeTasteTapped:
        guard !state.isComputingTaste else { return .none }
        state.errorMessage = nil
        state.isComputingTaste = true
        return computeTasteEffect(state: state)

      case let .tasteProfileComputed(.success(result)):
        state.isComputingTaste = false
        state.errorMessage = nil
        return .send(
          .delegate(
            .completed(
              cards: state.cards,
              votes: state.votes,
              tasteResult: result
            )
          )
        )

      case let .tasteProfileComputed(.failure(error)):
        state.isComputingTaste = false
        state.errorMessage = error.message
        return .none

      case .delegate:
        return .none
      }
    }
  }

  // MARK: - Effects

  private func fetchFlashcardsEffect(
    draft: OnboardingDraft,
    language: String
  ) -> Effect<Action> {
    let apiClient = self.onboardingAPIClient
    return .run { send in
      do {
        let cards = try await apiClient.fetchFlashcards(draft, language)
        await send(.flashcardsLoaded(.success(cards)))
      } catch {
        await send(.flashcardsLoaded(.failure(EquatableError(message: error.localizedDescription))))
      }
    }
    .cancellable(id: CancelID.fetchCards, cancelInFlight: true)
  }

  private func computeTasteEffect(state: State) -> Effect<Action> {
    var draft = state.draftSnapshot
    draft.cards = state.cards
    draft.votes = state.votes
    let language = state.language
    let apiClient = self.onboardingAPIClient

    return .run { send in
      do {
        let result = try await apiClient.computeTasteProfile(draft, language)
        await send(.tasteProfileComputed(.success(result)))
      } catch {
        await send(.tasteProfileComputed(.failure(EquatableError(message: error.localizedDescription))))
      }
    }
    .cancellable(id: CancelID.computeTaste, cancelInFlight: true)
  }
}
