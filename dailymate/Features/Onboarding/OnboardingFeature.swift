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
/// - Mỗi khi `draft` thay đổi sẽ tự lưu xuống `LocalClient`.
@Reducer
struct OnboardingFeature {
  @Reducer
  enum Path {
    case stage2(Stage2RegionFeature)
    case stage3(OnboardingPlaceholderStageFeature)
    case stage4(OnboardingPlaceholderStageFeature)
    case stage5(OnboardingPlaceholderStageFeature)
  }

  @ObservableState
  struct State: Equatable {
    static let totalStages = 5

    let userId: UUID
    var profile: UserProfile
    var draft: OnboardingDraft
    var stage1: Stage1PersonalFeature.State
    var path = StackState<Path.State>()

    var currentStage: Int { path.count + 1 }
    var canGoBack: Bool { !path.isEmpty }

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
      case completed
    }
  }

  @Dependency(\.localClient) var localClient
  @Dependency(\.date.now) var now

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

        state.path.append(.stage3(.init(stage: 3)))
        return .none

      case let .path(.element(id: _, action: action)):
        guard Self.isNext(action) else { return .none }
        let nextStage = state.currentStage + 1
        guard let next = Self.makeStage(nextStage, draft: state.draft) else { return .none }
        state.draft.step = max(state.draft.step, nextStage - 1)
        state.path.append(next)
        return .none

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
        let userId = state.userId
        let profileId = state.profile.profileId
        let localClient = self.localClient
        return .run { _ in
          localClient.saveDraft(newDraft, userId, profileId)
        }
      }
    }
  }

  // MARK: - Helpers

  private static func isNext(_ action: Path.Action) -> Bool {
    switch action {
    case .stage3(.delegate(.next)),
         .stage4(.delegate(.next)),
         .stage5(.delegate(.next)):
      return true
    default:
      return false
    }
  }

  private static func makeStage(_ stage: Int, draft: OnboardingDraft) -> Path.State? {
    switch stage {
    case 2: return .stage2(Stage2RegionFeature.State(draft: draft))
    case 3: return .stage3(.init(stage: 3))
    case 4: return .stage4(.init(stage: 4))
    case 5: return .stage5(.init(stage: 5))
    default: return nil
    }
  }
}

extension OnboardingFeature.Path.State: Equatable {}
