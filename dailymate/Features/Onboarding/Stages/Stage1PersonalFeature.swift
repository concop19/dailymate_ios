//
//  Stage1PersonalFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

/// Stage 1 — Làm quen: giới tính, năm sinh (avatar Lottie theo tuổi), chiều cao, cân nặng.
@Reducer
struct Stage1PersonalFeature {
  @ObservableState
  struct State: Equatable {
    var gender: Gender?
    var birthYear: Int?
    var heightCm: Double
    var weightKg: Double
    /// Bật sau khi bấm "Tiếp tục" lần đầu để hiển thị lỗi các trường còn thiếu.
    var showsValidation = false
    var shakeTrigger = 0
    let currentYear: Int

    var birthYearOptions: [Int] { Array((minBirthYear...maxBirthYear).reversed()) }
    static let heightRange: ClosedRange<Double> = 100...220
    static let weightRange: ClosedRange<Double> = 15...150

    init(
      gender: Gender? = nil,
      birthYear: Int? = nil,
      heightCm: Double = 165,
      weightKg: Double = 55,
      currentYear: Int = Calendar(identifier: .gregorian).component(.year, from: Date())
    ) {
      self.gender = gender
      self.currentYear = currentYear
      self.birthYear = birthYear.flatMap { (currentYear - 110...currentYear - 4).contains($0) ? $0 : nil }
      self.heightCm = min(max(heightCm, Self.heightRange.lowerBound), Self.heightRange.upperBound)
      self.weightKg = min(max(weightKg, Self.weightRange.lowerBound), Self.weightRange.upperBound)
    }

    /// Khôi phục từ bản nháp đã lưu trong LocalClient.
    init(draft: OnboardingDraft) {
      self.init(
        gender: draft.gender,
        birthYear: draft.birthYear,
        heightCm: draft.bodyMetrics?.heightCm ?? draft.heightCm,
        weightKg: draft.bodyMetrics?.weightKg ?? draft.weightKg
      )
    }

    // MARK: Derived

    /// Năm sinh hợp lệ: `minBirthYear <= năm <= maxBirthYear` (4 – 110 tuổi).
    var minBirthYear: Int { currentYear - 110 }
    var maxBirthYear: Int { currentYear - 4 }

    var birthYearError: String? {
      showsValidation && birthYear == nil ? "Vui lòng chọn năm sinh" : nil
    }

    var genderError: String? {
      showsValidation && gender == nil ? "Vui lòng chọn giới tính" : nil
    }

    var avatar: AnimationPlan {
      AnimationPlan.resolve(gender: gender, birthYear: birthYear, currentYear: currentYear)
    }

    var canContinue: Bool { gender != nil && birthYear != nil }
  }

  enum Action: Equatable {
    case genderSelected(Gender)
    case birthYearSelect(Int)
    case heightChanged(Double)
    case weightChanged(Double)
    case continueButtonTapped
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case completed(gender: Gender, birthYear: Int, heightCm: Double, weightKg: Double)
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .genderSelected(gender):
        state.gender = gender
        return .none

      case let .birthYearSelect(year):
        guard (state.minBirthYear...state.maxBirthYear).contains(year) else {
          state.birthYear = nil
          state.showsValidation = true
          return .none
        }
        state.birthYear = year
        return .none

      case let .heightChanged(value):
        state.heightCm = min(max(value, State.heightRange.lowerBound), State.heightRange.upperBound)
        return .none

      case let .weightChanged(value):
        state.weightKg = min(max(value, State.weightRange.lowerBound), State.weightRange.upperBound)
        return .none

      case .continueButtonTapped:
        guard let gender = state.gender, let birthYear = state.birthYear else {
          state.showsValidation = true
          state.shakeTrigger += 1
          return .none
        }
        return .send(
          .delegate(
            .completed(
              gender: gender,
              birthYear: birthYear,
              heightCm: state.heightCm,
              weightKg: state.weightKg
            )
          )
        )

      case .delegate:
        return .none
      }
    }
  }
}
