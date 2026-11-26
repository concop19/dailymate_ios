//
//  OnboardingFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

/// Container điều phối 5 stage Onboarding.
/// - Stage 1 là root của NavigationStack, Stage 2...5 được push vào `path` (StackState).
/// - Tiến trình hero: `currentStage = path.count + 1`.
/// - Mỗi khi `draft` thay đổi sẽ tự lưu xuống `LocalClient`; khi hoàn tất Stage 5 sẽ xoá bản nháp.
@Reducer
struct OnboardingFeature {
  @Reducer
  enum Path {
    case stage2(Stage2RegionFeature)
    case stage3(Stage3DietAllergyFeature)
    case stage4(Stage4FlashcardsFeature)
    case stage5(Stage5TasteSummaryFeature)
  }

  @ObservableState
  struct State: Equatable {
    static let totalStages = 5

    let userId: UUID
    var profile: UserProfile
    var draft: OnboardingDraft
    var stage1: Stage1PersonalFeature.State
    var path = StackState<Path.State>()
    var isCompleted = false

    var currentStage: Int { path.count + 1 }
    var canGoBack: Bool { !path.isEmpty }

    /// Phụ đề thanh Hero (vd: `"Thẻ 1/8"` khi đang ở Stage 4).
    var heroDetail: String? {
      guard case let .stage4(stage4State) = path.last else { return nil }
      return stage4State.progressDetail
    }

    init(userId: UUID, profile: UserProfile, draft: OnboardingDraft = OnboardingDraft()) {
      self.userId = userId
      self.profile = profile
      self.draft = draft
      self.stage1 = Stage1PersonalFeature.State(draft: draft)
    }
  }

  enum Action {
    case stage1(Stage1PersonalFeature.Action)
    case path(StackActionOf<Path>)
    case backButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      /// Hồ sơ đã lưu lên Supabase (đã có `profileId` thật).
      case completed(UserProfile)
    }
  }

  @Dependency(\.localClient) var localClient
  @Dependency(\.date.now) var now
  @Dependency(\.uuid) var uuid

  var body: some Reducer<State, Action> {
    Scope(state: \.stage1, action: \.stage1) {
      Stage1PersonalFeature()
    }

    Reduce { state, action in
      switch action {
      case let .stage1(.delegate(.completed(gender, birthYear, heightCm, weightKg))):
        state.draft.gender = gender
        state.draft.birthYear = birthYear
        state.draft.heightCm = heightCm
        state.draft.weightKg = weightKg
        state.draft.bodyMetrics = BodyMetrics(
          heightCm: heightCm,
          weightKg: weightKg,
          measuredAt: now,
          note: "onboarding"
        )
        state.draft.step = max(state.draft.step, 1)

        let currentYear = Calendar(identifier: .gregorian).component(.year, from: now)
        state.profile.gender = gender
        state.profile.birthYear = birthYear
        state.profile.age = max(1, currentYear - birthYear)

        state.path.append(.stage2(Stage2RegionFeature.State(draft: state.draft)))
        return .none

      case .stage1:
        return .none

      case let .path(.element(id: _, action: .stage2(.delegate(.completed(nation, homeRegion))))):
        state.draft.nation = nation
        state.draft.homeRegion = homeRegion
        state.draft.step = max(state.draft.step, 2)

        state.profile.nation = nation
        state.profile.homeRegion = state.draft.effectiveRegion

        state.path.append(.stage3(Stage3DietAllergyFeature.State(draft: state.draft)))
        return .none

      case let .path(.element(id: _, action: .stage3(.delegate(.completed(dietType, noAllergy, allergyGroups, allergyItems))))):
        let filtersChanged = state.draft.dietType != dietType
          || state.draft.noAllergy != noAllergy
          || state.draft.allergyGroups != allergyGroups
          || state.draft.allergyItems != allergyItems
        state.draft.dietType = dietType
        state.draft.noAllergy = noAllergy
        state.draft.allergyGroups = allergyGroups
        state.draft.allergyItems = allergyItems
        if filtersChanged {
          state.draft.cards = []
          state.draft.votes = [:]
          state.draft.tasteResult = nil
        }
        state.draft.step = max(state.draft.step, 3)

        state.profile.dietType = dietType

        state.path.append(.stage4(Stage4FlashcardsFeature.State(draft: state.draft)))
        return .none

      case let .path(.element(id: _, action: .stage4(.delegate(.completed(cards, votes, tasteResult))))):
        state.draft.cards = cards
        state.draft.votes = votes
        state.draft.tasteResult = tasteResult
        state.draft.step = max(state.draft.step, 4)

        state.profile.tasteWeight = tasteResult.tasteWeight
        state.profile.likedDishIds = tasteResult.likedDishIds
        state.profile.dislikedDishIds = tasteResult.dislikedDishIds
        // Sinh sẵn ID cho hồ sơ mới; được lưu cùng bản nháp để lần thử lại không tạo trùng.
        if !state.profile.isPersisted, state.draft.pendingProfileId == nil {
          state.draft.pendingProfileId = uuid()
        }

        state.path.append(
          .stage5(
            Stage5TasteSummaryFeature.State(
              draft: state.draft,
              existingProfileId: state.profile.isPersisted ? state.profile.profileId : nil
            )
          )
        )
        return .none

      case let .path(.element(id: _, action: .stage5(.delegate(.completed(finalDraft, savedProfileId))))):
        state.isCompleted = true
        state.draft = finalDraft
        // Bản nháp đang lưu dưới khoá của profileId cũ (có thể là khoá tạm) → xoá đúng khoá đó.
        let draftKey = state.profile.profileId
        state.profile.profileId = savedProfileId
        state.profile.isPersisted = true
        state.profile.dietType = finalDraft.dietType
        state.profile.tasteWeight = finalDraft.tasteResult?.tasteWeight ?? state.profile.tasteWeight
        state.profile.onboardingVersion = 1
        state.profile.onboardingCompletedAt = now

        let userId = state.userId
        let profile = state.profile
        let localClient = self.localClient
        return .run { send in
          localClient.clearDraft(userId, draftKey)
          await send(.delegate(.completed(profile)))
        }

      case .path:
        return .none

      case .backButtonTapped:
        guard !state.path.isEmpty else { return .none }
        state.path.removeLast()
        return .none

      case .delegate:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
    .onChange(of: \.draft) { _, newDraft in
      Reduce { state, _ in
        guard !state.isCompleted else { return .none }
        let userId = state.userId
        let profileId = state.profile.profileId
        let localClient = self.localClient
        return .run { _ in
          localClient.saveDraft(newDraft, userId, profileId)
        }
      }
    }
  }
}

extension OnboardingFeature.Path.State: Equatable {}
