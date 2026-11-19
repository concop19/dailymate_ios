//
//  OnboardingStage1Tests.swift
//  dailymateTests
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import dailymate

@Suite("AnimationPlan — chọn avatar theo tuổi & giới tính")
struct AnimationPlanTests {
  private let year = 2026

  @Test("Chưa nhập năm sinh → kitten / tabby-girl")
  func noBirthYear() {
    #expect(AnimationPlan.resolve(gender: nil, birthYear: nil, currentYear: year) == .kitten)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: nil, currentYear: year) == .kitten)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: nil, currentYear: year) == .tabbyGirl)
  }

  @Test("Ánh xạ đủ 8 avatar theo nhóm tuổi")
  func allGroups() {
    let cases: [(Gender?, Int, AnimationPlan)] = [
      (.male, 2016, .kitten), (.female, 2016, .tabbyGirl),
      (.male, 2000, .brother), (.female, 2000, .sister),
      (.male, 1985, .father), (.female, 1985, .mother),
      (.male, 1960, .grandpa), (.female, 1960, .grandma),
      (nil, 1985, .kitten),
    ]
    for (gender, birthYear, expected) in cases {
      #expect(AnimationPlan.resolve(gender: gender, birthYear: birthYear, currentYear: year) == expected)
    }
  }

  @Test("Ngưỡng biên 12/13, 29/30, 54/55")
  func boundaries() {
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 12, currentYear: year) == .kitten)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 13, currentYear: year) == .brother)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 29, currentYear: year) == .sister)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 30, currentYear: year) == .mother)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 54, currentYear: year) == .father)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 55, currentYear: year) == .grandpa)
  }
}

@MainActor
@Suite("Onboarding — Stage 1")
struct OnboardingStage1Tests {
  @Test("Năm sinh: lọc chữ số, tối đa 4 ký tự và kiểm tra khoảng hợp lệ")
  func birthYearValidation() async {
    let store = TestStore(initialState: Stage1PersonalFeature.State(currentYear: 2026)) {
      Stage1PersonalFeature()
    }

    await store.send(.birthYearChanged("20a15x9")) {
      $0.birthYearText = "2015"
    }
    #expect(store.state.birthYear == 2015)
    #expect(store.state.birthYearError == nil)

    await store.send(.birthYearChanged("1800")) {
      $0.birthYearText = "1800"
    }
    #expect(store.state.birthYear == nil)
    #expect(store.state.birthYearError != nil)

    await store.send(.birthYearChanged("2025")) {
      $0.birthYearText = "2025"
    }
    #expect(store.state.birthYear == nil) // < 4 tuổi
  }

  @Test("Bấm Tiếp tục khi thiếu dữ liệu → bật validation, không gửi delegate")
  func continueWithoutData() async {
    let store = TestStore(initialState: Stage1PersonalFeature.State(currentYear: 2026)) {
      Stage1PersonalFeature()
    }

    await store.send(.continueButtonTapped) {
      $0.showsValidation = true
      $0.shakeTrigger = 1
    }
    #expect(store.state.genderError != nil)
    #expect(store.state.birthYearError != nil)
  }

  @Test("Hoàn tất Stage 1 → cập nhật draft + BodyMetrics, push Stage 2, lưu LocalClient")
  func completeStage1() async {
    let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
    let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    let saved = LockIsolated<[(OnboardingDraft, UUID, String)]>([])

    let store = TestStore(
      initialState: OnboardingFeature.State(
        userId: userId,
        profile: OnboardingMapper.defaultStartupProfile()
      )
    ) {
      OnboardingFeature()
    } withDependencies: {
      $0.date.now = fixedNow
      $0.localClient.saveDraft = { draft, userId, profileId in
        saved.withValue { $0.append((draft, userId, profileId)) }
      }
    }

    #expect(store.state.currentStage == 1)

    await store.send(.stage1(.genderSelected(.male))) {
      $0.stage1.gender = .male
    }
    await store.send(.stage1(.birthYearChanged("2015"))) {
      $0.stage1.birthYearText = "2015"
    }
    await store.send(.stage1(.heightChanged(151))) {
      $0.stage1.heightCm = 151
    }
    await store.send(.stage1(.weightChanged(35.5))) {
      $0.stage1.weightKg = 35.5
    }
    await store.send(.stage1(.continueButtonTapped))
    await store.receive(\.stage1.delegate.completed) {
      $0.draft.gender = .male
      $0.draft.birthYear = 2015
      $0.draft.heightCm = 151
      $0.draft.weightKg = 35.5
      $0.draft.bodyMetrics = BodyMetrics(heightCm: 151, weightKg: 35.5, measuredAt: fixedNow, note: "onboarding")
      $0.draft.step = 1
      let expectedYear = Calendar(identifier: .gregorian).component(.year, from: fixedNow)
      $0.profile.gender = .male
      $0.profile.birthYear = 2015
      $0.profile.age = max(1, expectedYear - 2015)
      $0.path.append(.stage2(Stage2RegionFeature.State(draft: $0.draft)))
    }
    await store.finish()

    #expect(store.state.currentStage == 2)
    #expect(saved.value.count == 1)
    #expect(saved.value.last?.0 == store.state.draft)
    #expect(saved.value.last?.1 == userId)
    #expect(saved.value.last?.2 == OnboardingMapper.defaultProfileId)

    await store.send(.backButtonTapped) {
      $0.path.removeLast()
    }
    #expect(store.state.currentStage == 1)
  }
}

@MainActor
@Suite("Onboarding — Stage 2 (Quốc gia & Vùng miền)")
struct OnboardingStage2Tests {
  @Test("Mặc định là Việt Nam, bắt buộc chọn 1 trong 3 miền mới cho qua")
  func vietnamRequiresRegion() async {
    let store = TestStore(initialState: Stage2RegionFeature.State()) {
      Stage2RegionFeature()
    }

    #expect(store.state.nation == .vietnam)
    #expect(store.state.showsVietnameseRegions == true)
    #expect(store.state.canContinue == false)

    await store.send(.continueButtonTapped) {
      $0.showsValidation = true
      $0.shakeTrigger = 1
    }
    #expect(store.state.regionError != nil)

    await store.send(.regionSelected(.central)) {
      $0.homeRegion = .central
      $0.showsValidation = false
    }
    #expect(store.state.canContinue == true)
    #expect(store.state.regionError == nil)

    await store.send(.continueButtonTapped)
    await store.receive(\.delegate.completed)
  }

  @Test("Chọn Nước khác → ẩn 3 miền, cho phép qua ngay với homeRegion = nil")
  func otherNationSkipsRegion() async {
    let store = TestStore(initialState: Stage2RegionFeature.State(nation: .vietnam, homeRegion: .northern)) {
      Stage2RegionFeature()
    }

    await store.send(.nationSelected(.other)) {
      $0.nation = .other
    }
    #expect(store.state.showsVietnameseRegions == false)
    #expect(store.state.canContinue == true)

    await store.send(.continueButtonTapped)
    await store.receive(.delegate(.completed(nation: .other, homeRegion: nil)))
  }
}
