//
//  Stage5TasteSummaryFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

/// Stage 5 — Tổng kết khẩu vị & hoàn tất Onboarding ("Khẩu vị của bạn").
@Reducer
struct Stage5TasteSummaryFeature {
  struct DimensionRow: Equatable, Identifiable, Sendable {
    var id: TasteDimension { dimension }
    let dimension: TasteDimension
    let value: Double
    let percentageText: String
    let isTopThree: Bool
  }

  @ObservableState
  struct State: Equatable {
    var draft: OnboardingDraft
    let profileId: String
    var tasteWeight: TasteVector
    var tasteSource: TasteSource
    var isEditingTaste = false
    /// Giữ thứ tự hàng cố định trong lúc người dùng kéo thanh vị giác để không bị nhảy hàng dưới ngón tay.
    var editingOrder: [TasteDimension]? = nil
    var isSubmitting = false
    var errorMessage: String? = nil

    init(
      draft: OnboardingDraft,
      profileId: String = OnboardingMapper.defaultProfileId
    ) {
      self.draft = draft
      self.profileId = profileId
      self.tasteWeight = draft.tasteResult?.tasteWeight ?? .default
      self.tasteSource = draft.tasteResult?.source ?? .region
    }

    // MARK: Derived

    var topThreeDimensions: Set<TasteDimension> {
      Set(TasteDimension.sortedByWeight(in: tasteWeight).prefix(3))
    }

    var dimensionRows: [DimensionRow] {
      let ordered = editingOrder ?? TasteDimension.sortedByWeight(in: tasteWeight)
      let top3 = topThreeDimensions
      return ordered.map { dim in
        let val = min(max(dim.value(in: tasteWeight), 0), 1)
        let pct = Int((val * 100).rounded())
        return DimensionRow(
          dimension: dim,
          value: val,
          percentageText: "\(pct)%",
          isTopThree: top3.contains(dim)
        )
      }
    }

    var topThreeHeadline: String {
      TasteDimension.topThreeHeadline(for: tasteWeight)
    }

    var sourceSubtitle: String {
      switch tasteSource {
      case .flashcards:
        "Tính từ các món bạn vừa chọn, kết hợp vị vùng miền."
      case .region:
        "Tính từ khẩu vị đặc trưng vùng miền của bạn."
      }
    }

    var regionSummaryEmoji: String {
      if draft.nation == .other {
        return "🌍"
      }
      return (draft.homeRegion ?? .national).displayEmoji
    }

    var regionSummaryTitle: String {
      if draft.nation == .other {
        return "Quốc tế"
      }
      return (draft.homeRegion ?? .national).displayTitle
    }

    var dietSummaryEmoji: String {
      draft.dietType.displayEmoji
    }

    var dietSummaryTitle: String {
      draft.dietType.displayTitle
    }

    var hasNoAllergy: Bool {
      draft.noAllergy || (draft.allergyGroups.isEmpty && draft.allergyItems.isEmpty)
    }

    var allergySummaryTitle: String {
      if hasNoAllergy {
        return "Không dị ứng gì"
      }
      var labels: [String] = draft.allergyGroups.map(\.displayTitle)
      labels.append(contentsOf: draft.allergyItems.map(\.name))
      if labels.count <= 2 {
        return "Không ăn: " + labels.joined(separator: ", ")
      }
      let firstTwo = labels.prefix(2).joined(separator: ", ")
      return "Không ăn: \(firstTwo) (+\(labels.count - 2))"
    }
  }

  enum Action: Equatable {
    case toggleEditTasteTapped
    case tasteValueChanged(TasteDimension, Double)
    case finishButtonTapped
    case completeOnboardingResponse(Result<Bool, EquatableError>)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case completed(finalDraft: OnboardingDraft)
    }
  }

  struct EquatableError: Error, Equatable, Sendable {
    let message: String
  }

  @Dependency(\.onboardingSupabaseClient) var onboardingSupabaseClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .toggleEditTasteTapped:
        state.isEditingTaste.toggle()
        if state.isEditingTaste {
          state.editingOrder = TasteDimension.sortedByWeight(in: state.tasteWeight)
        } else {
          state.editingOrder = nil
        }
        return .none

      case let .tasteValueChanged(dimension, newValue):
        let rounded = (min(max(newValue, 0), 1) * 100).rounded() / 100
        dimension.setValue(rounded, in: &state.tasteWeight)
        state.draft.tasteResult = TasteResult(
          tasteWeight: state.tasteWeight,
          source: state.tasteSource,
          likedDishIds: state.draft.tasteResult?.likedDishIds ?? [],
          dislikedDishIds: state.draft.tasteResult?.dislikedDishIds ?? []
        )
        return .none

      case .finishButtonTapped:
        guard !state.isSubmitting else { return .none }
        state.isEditingTaste = false
        state.editingOrder = nil
        state.isSubmitting = true
        state.errorMessage = nil

        state.draft.tasteResult = TasteResult(
          tasteWeight: state.tasteWeight,
          source: state.tasteSource,
          likedDishIds: state.draft.tasteResult?.likedDishIds ?? [],
          dislikedDishIds: state.draft.tasteResult?.dislikedDishIds ?? []
        )
        state.draft.step = 5

        let finalDraft = state.draft
        let profileId = state.profileId
        let supabaseClient = self.onboardingSupabaseClient

        return .run { send in
          do {
            try await supabaseClient.completeOnboarding(finalDraft, profileId)
            await send(.completeOnboardingResponse(.success(true)))
          } catch {
            await send(
              .completeOnboardingResponse(
                .failure(EquatableError(message: error.localizedDescription))
              )
            )
          }
        }

      case .completeOnboardingResponse(.success):
        state.isSubmitting = false
        state.errorMessage = nil
        return .send(.delegate(.completed(finalDraft: state.draft)))

      case let .completeOnboardingResponse(.failure(error)):
        state.isSubmitting = false
        state.errorMessage = error.message
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
