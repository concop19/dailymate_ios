//
//  Stage2RegionFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

/// Stage 2 — Quốc gia & Vùng miền ("Bạn quen ăn vị vùng nào?").
@Reducer
struct Stage2RegionFeature {
  @ObservableState
  struct State: Equatable {
    var nation: Nation
    var homeRegion: HomeRegion?
    var showsValidation = false
    var shakeTrigger = 0

    /// 3 miền hiển thị khi chọn Việt Nam.
    static let vietnameseRegions: [HomeRegion] = [.northern, .central, .southern]

    init(
      nation: Nation = .vietnam,
      homeRegion: HomeRegion? = nil
    ) {
      self.nation = nation
      if let homeRegion, Self.vietnameseRegions.contains(homeRegion) {
        self.homeRegion = homeRegion
      } else {
        self.homeRegion = nil
      }
    }

    init(draft: OnboardingDraft) {
      self.init(
        nation: draft.nation,
        homeRegion: draft.homeRegion
      )
    }

    // MARK: Derived

    var showsVietnameseRegions: Bool {
      nation == .vietnam
    }

    var canContinue: Bool {
      switch nation {
      case .vietnam:
        return homeRegion != nil
      case .other:
        return true
      }
    }

    var regionError: String? {
      guard showsValidation, nation == .vietnam, homeRegion == nil else {
        return nil
      }
      return "Vui lòng chọn miền bạn quen ăn"
    }
  }

  enum Action: Equatable {
    case nationSelected(Nation)
    case regionSelected(HomeRegion)
    case continueButtonTapped
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case completed(nation: Nation, homeRegion: HomeRegion?)
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .nationSelected(nation):
        state.nation = nation
        if nation == .other {
          state.showsValidation = false
        }
        return .none

      case let .regionSelected(region):
        guard State.vietnameseRegions.contains(region) else { return .none }
        state.homeRegion = region
        state.showsValidation = false
        return .none

      case .continueButtonTapped:
        guard state.canContinue else {
          state.showsValidation = true
          state.shakeTrigger += 1
          return .none
        }
        let resolvedRegion: HomeRegion? = state.nation == .vietnam ? state.homeRegion : nil
        return .send(
          .delegate(
            .completed(
              nation: state.nation,
              homeRegion: resolvedRegion
            )
          )
        )

      case .delegate:
        return .none
      }
    }
  }
}

// MARK: - HomeRegion UI Metadata

extension HomeRegion {
  var displayTitle: String {
    switch self {
    case .northern: "Miền Bắc"
    case .central: "Miền Trung"
    case .southern: "Miền Nam"
    case .national: "Toàn quốc"
    }
  }

  var displaySubtitle: String {
    switch self {
    case .northern: "Thanh, vừa vị — phở, bún chả, canh cua"
    case .central: "Đậm, cay nồng — bún bò, mì Quảng"
    case .southern: "Ngọt dịu, nhiều rau — canh chua, cá kho"
    case .national: "Khẩu vị hài hoà chung"
    }
  }

  var displayEmoji: String {
    switch self {
    case .northern: "🏞️"
    case .central: "🌶️"
    case .southern: "🥥"
    case .national: "🌏"
    }
  }
}
