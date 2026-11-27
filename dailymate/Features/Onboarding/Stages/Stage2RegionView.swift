//
//  Stage2RegionView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import SwiftUI

struct Stage2RegionView: View {
  let store: StoreOf<Stage2RegionFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 26) {
        header
        nationSection

        if store.showsVietnameseRegions {
          regionSection
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom) { continueBar }
    .background { PaperBackground() }
    .toolbar(.hidden, for: .navigationBar)
  }

  // MARK: - Header

  private var header: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Bạn quen ăn vị vùng nào?")
        .font(.system(.largeTitle, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .fixedSize(horizontal: false, vertical: true)

      MascotBanner(
        message: "Mình sẽ mở khoá thêm đặc sản đúng vùng quê và làm nền khẩu vị cho bạn.",
        animationName: "Cattr",
        mascotSize: 88
      )
    }
  }

  // MARK: - Nation

  private var nationSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      OnboardingSectionLabel("Quốc gia")

      HStack(spacing: 14) {
        OnboardingChoiceCard(
          emoji: "🇻🇳",
          title: "Việt Nam",
          isSelected: store.nation == .vietnam
        ) {
          store.send(.nationSelected(.vietnam))
        }

        OnboardingChoiceCard(
          emoji: "🌍",
          title: "Nước khác",
          isSelected: store.nation == .other
        ) {
          store.send(.nationSelected(.other))
        }
      }
    }
  }

  // MARK: - Vietnamese Regions

  private var regionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      OnboardingSectionLabel("Bạn đến từ miền nào (hoặc quen ăn vị miền nào)?")

      VStack(spacing: 12) {
        ForEach(Stage2RegionFeature.State.vietnameseRegions, id: \.self) { region in
          OnboardingRadioRow(
            image: region.displayEmoji,
            title: region.displayTitle,
            subtitle: region.displaySubtitle,
            isSelected: store.homeRegion == region
          ) {
            store.send(.regionSelected(region))
          }
        }
      }

      if let error = store.regionError {
        ErrorText(error)
      }
    }
  }

  // MARK: - Continue

  private var continueBar: some View {
    GhibliPrimaryButton(title: "Tiếp tục →", color: Color.Ghibli.wood) {
      store.send(.continueButtonTapped)
    }
    .opacity(store.canContinue ? 1 : 0.45)
    .shake(trigger: store.shakeTrigger)
    .padding(.horizontal, 24)
    .padding(.top, 12)
    .padding(.bottom, 8)
    .background(Color.Ghibli.cream.opacity(0.95))
    .overlay(alignment: .top) {
      Rectangle().fill(Color.Ghibli.straw.opacity(0.25)).frame(height: 1)
    }
  }
}

#Preview {
  NavigationStack {
    Stage2RegionView(
      store: Store(initialState: Stage2RegionFeature.State()) {
        Stage2RegionFeature()
      }
    )
  }
}
