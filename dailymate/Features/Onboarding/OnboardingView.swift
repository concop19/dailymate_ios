//
//  OnboardingView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
  @Bindable var store: StoreOf<OnboardingFeature>

  var body: some View {
    VStack(spacing: 0) {
      OnboardingHeroProgressView(
        currentStage: store.currentStage,
        totalStages: OnboardingFeature.State.totalStages,
        canGoBack: store.canGoBack,
        onBack: { store.send(.backButtonTapped) }
      )
      .padding(.horizontal, 24)
      .padding(.top, 8)
      .padding(.bottom, 16)

      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        Stage1PersonalView(store: store.scope(state: \.stage1, action: \.stage1))
      } destination: { store in
        switch store.case {
        case let .stage2(store): OnboardingPlaceholderStageView(store: store)
        case let .stage3(store): OnboardingPlaceholderStageView(store: store)
        case let .stage4(store): OnboardingPlaceholderStageView(store: store)
        case let .stage5(store): OnboardingPlaceholderStageView(store: store)
        }
      }
    }
    .background { OnboardingBackground() }
  }
}

#Preview {
  OnboardingView(
    store: Store(
      initialState: OnboardingFeature.State(
        userId: UUID(),
        profile: OnboardingMapper.defaultStartupProfile()
      )
    ) {
      OnboardingFeature()
    } withDependencies: {
      $0.localClient = .previewValue
    }
  )
}
