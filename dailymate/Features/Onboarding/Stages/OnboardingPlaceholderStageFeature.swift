//
//  OnboardingPlaceholderStageFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import SwiftUI

/// Màn tạm cho Stage 2...5 trong lúc chưa xây dựng — chỉ để kiểm tra điều hướng StackState & Hero.
@Reducer
struct OnboardingPlaceholderStageFeature {
  @ObservableState
  struct State: Equatable {
    let stage: Int
  }

  enum Action: Equatable {
    case continueButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case next
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case .continueButtonTapped:
        return .send(.delegate(.next))
      case .delegate:
        return .none
      }
    }
  }
}

struct OnboardingPlaceholderStageView: View {
  let store: StoreOf<OnboardingPlaceholderStageFeature>

  private var isLastStage: Bool { store.stage >= OnboardingFeature.State.totalStages }

  var body: some View {
    VStack(spacing: 20) {
      Spacer()
      Text("🚧")
        .font(.system(size: 64))
      Text("Bước \(store.stage) đang được xây dựng")
        .font(.system(.title2, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
      Text("Màn hình này sẽ được hoàn thiện ở các bước tiếp theo.")
        .font(.subheadline)
        .foregroundStyle(Color.Ghibli.inkMuted)
        .multilineTextAlignment(.center)
      Spacer()

      if !isLastStage {
        GhibliPrimaryButton(title: "Tiếp tục →", color: Color.Ghibli.wood) {
          store.send(.continueButtonTapped)
        }
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { OnboardingBackground() }
    .toolbar(.hidden, for: .navigationBar)
  }
}
