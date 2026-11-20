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
    var birthYearText: String
    var heightCm: Double
    var weightKg: Double
    /// Bật sau khi bấm "Tiếp tục" lần đầu để hiển thị lỗi các trường còn thiếu.
    var showsValidation = false
    var shakeTrigger = 0
    let currentYear: Int

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
      self.birthYearText = birthYear.map(String.init) ?? ""
      self.heightCm = min(max(heightCm, Self.heightRange.lowerBound), Self.heightRange.upperBound)
      self.weightKg = min(max(weightKg, Self.weightRange.lowerBound), Self.weightRange.upperBound)
      self.currentYear = currentYear
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

    var birthYear: Int? {
      guard birthYearText.count == 4, let year = Int(birthYearText),
            (minBirthYear...maxBirthYear).contains(year) else { return nil }
      return year
    }

    var birthYearError: String? {
      if birthYearText.isEmpty {
        return showsValidation ? "Vui lòng nhập năm sinh" : nil
      }
      guard birthYearText.count == 4, let year = Int(birthYearText) else {
        return showsValidation ? "Năm sinh gồm 4 chữ số" : nil
      }
      if year < minBirthYear { return "Năm sinh phải từ \(minBirthYear) trở về sau" }
      if year > maxBirthYear { return "Năm sinh không được sau \(maxBirthYear)" }
      return nil
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
    case birthYearChanged(String)
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

      case let .birthYearChanged(text):
        // Chỉ giữ chữ số, tối đa 4 ký tự.
        state.birthYearText = String(text.filter(\.isWholeNumber).prefix(4))
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
