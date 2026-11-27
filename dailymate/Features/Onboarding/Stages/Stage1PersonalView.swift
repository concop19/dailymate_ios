//
//  Stage1PersonalView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Lottie
import SwiftUI

struct Stage1PersonalView: View {
  @Bindable var store: StoreOf<Stage1PersonalFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        header
        genderSection
        avatarSection
        birthYearSection
        heightSection
        weightSection
      }
      .padding(.horizontal, 24) // lề trái phải
      .padding(.top, 8) // lề trên
      .padding(.bottom, 24) // lề dưới
    }
    .scrollIndicators(.hidden) // ẩn chỉ thanh cuộn
    .safeAreaInset(edge: .bottom) { continueBar }
      // fixed area dù cuônj thì thàn phần này vẫn ko bị cuon di
    .background { PaperBackground() }
      // đặt background vstack này là onboardng backgroudn
    .toolbar(.hidden, for: .navigationBar)
      // ẩn thanh navigationBar mặc định của hệ thống
  }

  // MARK: - Header

  private var header: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Chào bạn! Mình làm quen nhé ")
        .font(.system(.largeTitle, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .fixedSize(horizontal: false, vertical: true)

      MascotBanner(
        message: "Vài chỉ số cơ bản giúp Daily Mate cân đối năng lượng cho từng bữa.",
        animationName: "cat_gosh",
        mascotSize: 88
      )
    }
  }

  // MARK: - Gender

  private var genderSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      OnboardingSectionLabel("Giới tính")

      HStack(spacing: 14) {
        OnboardingChoiceCard(title: "Nam", isSelected: store.gender == .male) {
          store.send(.genderSelected(.male))
        }
        OnboardingChoiceCard(title: "Nữ", isSelected: store.gender == .female) {
          store.send(.genderSelected(.female))
        }
      }

      if let error = store.genderError {
        ErrorText(error)
      }
    }
  }

  // MARK: - Avatar

  private var avatarSection: some View {
    VStack(spacing: 8) {
      LottieView(animation: .named(store.avatar.animationName))
        .playing(loopMode: .loop)
        .resizable()
        .scaledToFit()
        .frame(width: 150, height: 150)
        .id(store.avatar)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .accessibilityHidden(true)

      Text("Avatar theo năm sinh và giới tính")
        .font(.subheadline)
        .foregroundStyle(Color.Ghibli.inkMuted)
    }
    .frame(maxWidth: .infinity)
    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: store.avatar)
  }

  // MARK: - Birth year

  private var birthYearSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      OnboardingSectionLabel("Năm sinh *")

      Menu {
        ForEach(store.birthYearOptions, id: \.self) { year in
          Button {
            store.send(.birthYearSelect(year))
          } label: {
            if store.birthYear == year {
              Label(String(year), systemImage: "checkmark")
            } else {
              Text(String(year))
            }
          }
        }
      } label: {
        HStack {
          Text(store.birthYear.map(String.init) ?? "Chọn năm sinh")
            .foregroundStyle(
              store.birthYear == nil ? Color.Ghibli.inkMuted : Color.Ghibli.inkDark
            )
          Spacer()
          Image(systemName: "chevron.down")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.Ghibli.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .ghibliInputContainer(isFocused: false)
        .overlay {
          if store.birthYearError != nil {
            RoundedRectangle(cornerRadius: 14)
              .strokeBorder(Color.red.opacity(0.6), lineWidth: 1.5)
          }
        }
      }

      if let error = store.birthYearError {
        ErrorText(error)
      } else {
        Text("Từ \(store.minBirthYear) đến \(store.maxBirthYear)")
          .font(.caption)
          .foregroundStyle(Color.Ghibli.inkMuted)
      }
    }
  }

  // MARK: - Height & Weight

  private var heightSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      OnboardingSectionLabel("Chiều cao")
      GhibliRulerPicker(
        value: $store.heightCm.sending(\.heightChanged),
        range: Stage1PersonalFeature.State.heightRange,
        step: 1,
        majorEvery: 10,
        unit: "cm"
      )
    }
  }

  private var weightSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      OnboardingSectionLabel("Cân nặng")
      GhibliRulerPicker(
        value: $store.weightKg.sending(\.weightChanged),
        range: Stage1PersonalFeature.State.weightRange,
        step: 0.5,
        majorEvery: 10,
        unit: "kg",
        fractionDigits: 1,
        style: .curved
      )
      BMISummaryBadgeView(heightCm: store.heightCm, weightKg: store.weightKg)
        .padding(.top, 8)
    }
  }

  // MARK: - Continue

  private var continueBar: some View {
    GhibliPrimaryButton(title: "Tiếp tục →", color: Color.Ghibli.wood) {
      store.send(.continueButtonTapped)
    }
    .opacity(store.canContinue ? 1 : 0.75)
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

// MARK: - Shared small views

struct OnboardingSectionLabel: View {
  let text: String
  init(_ text: String) { self.text = text }

  var body: some View {
    Text(text)
      .font(.headline.weight(.bold))
      .foregroundStyle(Color.Ghibli.inkDark)
  }
}

#Preview {
  NavigationStack {
    Stage1PersonalView(
      store: Store(initialState: Stage1PersonalFeature.State(birthYear: 2015, heightCm: 151, weightKg: 35.5)) {
        Stage1PersonalFeature()
      }
    )
  }
}
