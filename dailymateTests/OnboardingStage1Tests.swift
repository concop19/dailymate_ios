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

@MainActor
@Suite("Onboarding — Stage 3 (Chế độ ăn & Dị ứng)")
struct OnboardingStage3Tests {
  @Test("Chọn cả nhóm dị ứng qua Bottom Sheet Bước 1 và thử bấm Không dị ứng gì")
  func selectWholeAllergyGroupAndNoAllergy() async {
    let store = TestStore(initialState: Stage3DietAllergyFeature.State()) {
      Stage3DietAllergyFeature()
    }

    #expect(store.state.dietType == .omnivore)
    #expect(store.state.canContinue == false)

    await store.send(.continueButtonTapped) {
      $0.showsValidation = true
      $0.shakeTrigger = 1
    }
    #expect(store.state.allergyError != nil)

    await store.send(.dietTypeSelected(.vegetarian)) {
      $0.dietType = .vegetarian
    }

    await store.send(.allergyGroupChipTapped(.seafood)) {
      $0.activeSheet = Stage3DietAllergyFeature.AllergySheetState(
        group: .seafood,
        step: .scopeSelection,
        searchQuery: "",
        draftSelectedItems: []
      )
    }

    await store.send(.sheetAllGroupSelected) {
      $0.allergyGroups = [.seafood]
      $0.noAllergy = false
      $0.showsValidation = false
      $0.activeSheet = nil
    }
    #expect(store.state.canContinue == true)
    #expect(store.state.badgeText(for: .seafood) == "Tất cả")

    // Bấm "Không dị ứng gì" sẽ xoá toàn bộ nhóm & nguyên liệu đã chọn
    await store.send(.noAllergyTapped) {
      $0.noAllergy = true
      $0.allergyGroups = []
      $0.allergyItems = []
    }
    #expect(store.state.canContinue == true)

    await store.send(.continueButtonTapped)
    await store.receive(
      .delegate(
        .completed(
          dietType: .vegetarian,
          noAllergy: true,
          allergyGroups: [],
          allergyItems: []
        )
      )
    )
  }

  @Test("Chọn Chỉ một số loại → gọi API lấy nguyên liệu, tìm kiếm, tick chọn và bấm Xong")
  func selectSpecificAllergyIngredients() async {
    let mockItems = [
      AllergyItem(id: 101, name: "tôm", group: .seafood),
      AllergyItem(id: 102, name: "cua", group: .seafood),
      AllergyItem(id: 103, name: "mực", group: .seafood),
    ]

    let store = TestStore(
      initialState: Stage3DietAllergyFeature.State(allergyGroups: [.seafood])
    ) {
      Stage3DietAllergyFeature()
    } withDependencies: {
      $0.onboardingAPIClient.fetchAllergyIngredients = { group, _ in
        #expect(group == .seafood)
        return mockItems
      }
    }

    await store.send(.allergyGroupChipTapped(.seafood)) {
      $0.activeSheet = Stage3DietAllergyFeature.AllergySheetState(
        group: .seafood,
        step: .scopeSelection
      )
    }

    await store.send(.sheetSomeItemsSelected) {
      $0.activeSheet?.step = .ingredientPicker
      $0.activeSheet?.isLoadingIngredients = true
    }

    await store.receive(\.allergyIngredientsLoaded) {
      $0.cachedIngredientsByGroup[.seafood] = mockItems
      $0.activeSheet?.isLoadingIngredients = false
    }

    await store.send(.sheetSearchQueryChanged("tom")) {
      $0.activeSheet?.searchQuery = "tom"
    }
    #expect(store.state.filteredSheetIngredients.map(\.id) == [101])

    await store.send(.sheetIngredientToggled(mockItems[0])) {
      $0.activeSheet?.draftSelectedItems = [mockItems[0]]
    }
    await store.send(.sheetIngredientToggled(mockItems[1])) {
      $0.activeSheet?.draftSelectedItems = [mockItems[0], mockItems[1]]
    }

    await store.send(.sheetDoneButtonTapped) {
      $0.allergyGroups = []
      $0.allergyItems = [mockItems[0], mockItems[1]]
      $0.noAllergy = false
      $0.activeSheet = nil
    }

    #expect(store.state.badgeText(for: .seafood) == "2")
    #expect(store.state.canContinue == true)
  }
}

@MainActor
@Suite("Onboarding — Stage 4 (Flashcards & Taste Profile)")
struct OnboardingStage4Tests {
  private static let sampleCards = [
    Flashcard(
      dishId: "dish_1",
      title: "Cá đối kho tiêu",
      imageURL: nil,
      label: "Mặn đậm",
      tasteProfile: .default
    ),
    Flashcard(
      dishId: "dish_2",
      title: "Canh chua cá lóc",
      imageURL: nil,
      label: "Chua thanh",
      tasteProfile: .default
    ),
    Flashcard(
      dishId: "dish_3",
      title: "Thịt kho tàu",
      imageURL: nil,
      label: "Ngọt dịu",
      tasteProfile: .default
    ),
  ]

  @Test("onAppear tải flashcards → vote đủ 3 thẻ → gọi computeTasteProfile và trả TasteResult")
  func fetchAndVoteAllCards() async {
    let expectedTaste = TasteResult(
      tasteWeight: TasteVector(
        sweet: 0.6, sour: 0.5, salty: 0.7, bitter: 0.1,
        umami: 0.8, spicy: 0.4, astringent: 0.1
      ),
      source: .flashcards,
      likedDishIds: ["dish_1"],
      dislikedDishIds: ["dish_2"]
    )

    let capturedVotes = LockIsolated<[String: SwipeVote]>([:])

    let store = TestStore(
      initialState: Stage4FlashcardsFeature.State(draft: OnboardingDraft())
    ) {
      Stage4FlashcardsFeature()
    } withDependencies: {
      $0.onboardingAPIClient.fetchFlashcards = { _, _ in
        Self.sampleCards
      }
      $0.onboardingAPIClient.computeTasteProfile = { draft, _ in
        capturedVotes.setValue(draft.votes)
        return expectedTaste
      }
    }

    await store.send(.onAppear) {
      $0.isLoadingCards = true
    }

    await store.receive(\.flashcardsLoaded) {
      $0.isLoadingCards = false
      $0.cards = Self.sampleCards
      $0.currentIndex = 0
    }
    #expect(store.state.progressDetail == "Thẻ 1/3")

    await store.send(.voteSubmitted(.like)) {
      $0.votes["dish_1"] = .like
      $0.currentIndex = 1
    }
    #expect(store.state.progressDetail == "Thẻ 2/3")

    await store.send(.voteSubmitted(.dislike)) {
      $0.votes["dish_2"] = .dislike
      $0.currentIndex = 2
    }
    #expect(store.state.progressDetail == "Thẻ 3/3")

    await store.send(.voteSubmitted(.neutral)) {
      $0.votes["dish_3"] = .neutral
      $0.isComputingTaste = true
    }

    await store.receive(\.tasteProfileComputed) {
      $0.isComputingTaste = false
    }

    await store.receive(
      .delegate(
        .completed(
          cards: Self.sampleCards,
          votes: [
            "dish_1": .like,
            "dish_2": .dislike,
            "dish_3": .neutral,
          ],
          tasteResult: expectedTaste
        )
      )
    )

    #expect(capturedVotes.value == [
      "dish_1": .like,
      "dish_2": .dislike,
      "dish_3": .neutral,
    ])
  }

  @Test("Bấm Bỏ qua → xoá votes và gọi computeTasteProfile theo vùng miền")
  func skipToRegionTaste() async {
    let regionTaste = TasteResult(
      tasteWeight: .default,
      source: .region,
      likedDishIds: [],
      dislikedDishIds: []
    )

    let store = TestStore(
      initialState: Stage4FlashcardsFeature.State(
        draft: OnboardingDraft(
          cards: Self.sampleCards,
          votes: ["dish_1": .like]
        )
      )
    ) {
      Stage4FlashcardsFeature()
    } withDependencies: {
      $0.onboardingAPIClient.computeTasteProfile = { draft, _ in
        #expect(draft.votes.isEmpty)
        return regionTaste
      }
    }

    await store.send(.skipToRegionTasteTapped) {
      $0.votes = [:]
      $0.isComputingTaste = true
    }

    await store.receive(\.tasteProfileComputed) {
      $0.isComputingTaste = false
    }

    await store.receive(
      .delegate(
        .completed(
          cards: Self.sampleCards,
          votes: [:],
          tasteResult: regionTaste
        )
      )
    )
  }
}

@MainActor
@Suite("Onboarding — Stage 5 (Tổng kết Khẩu vị & Hoàn tất)")
struct OnboardingStage5Tests {
  @Test("Sắp xếp 7 chiều vị giác giảm dần, chỉnh thanh vị giác và gọi completeOnboarding lên Supabase")
  func editTasteAndCompleteOnboarding() async {
    let initialVector = TasteVector(
      sweet: 0.31,
      sour: 0.31,
      salty: 0.54,
      bitter: 0.25,
      umami: 0.52,
      spicy: 0.51,
      astringent: 0.30
    )
    let initialDraft = OnboardingDraft(
      step: 4,
      gender: .male,
      birthYear: 2000,
      nation: .vietnam,
      homeRegion: .central,
      dietType: .omnivore,
      noAllergy: true,
      tasteResult: TasteResult(
        tasteWeight: initialVector,
        source: .flashcards,
        likedDishIds: ["dish_1"],
        dislikedDishIds: ["dish_2"]
      )
    )

    let completedDraft = LockIsolated<OnboardingDraft?>(nil)
    let completedProfileId = LockIsolated<String?>(nil)

    let store = TestStore(
      initialState: Stage5TasteSummaryFeature.State(
        draft: initialDraft,
        profileId: OnboardingMapper.defaultProfileId
      )
    ) {
      Stage5TasteSummaryFeature()
    } withDependencies: {
      $0.onboardingSupabaseClient.completeOnboarding = { draft, profileId in
        completedDraft.setValue(draft)
        completedProfileId.setValue(profileId)
      }
    }

    #expect(store.state.topThreeHeadline == "Đậm đà · Ngọt thịt · Cay — mình nhớ rồi nha!")
    #expect(store.state.dimensionRows.prefix(3).map(\.dimension) == [.salty, .umami, .spicy])
    #expect(store.state.regionSummaryTitle == "Miền Trung")
    #expect(store.state.dietSummaryTitle == "Ăn mặn")
    #expect(store.state.allergySummaryTitle == "Không dị ứng gì")

    let fixedOrder = TasteDimension.sortedByWeight(in: initialVector)

    await store.send(.toggleEditTasteTapped) {
      $0.isEditingTaste = true
      $0.editingOrder = fixedOrder
    }

    await store.send(.tasteValueChanged(.spicy, 0.85)) {
      $0.tasteWeight.spicy = 0.85
      $0.draft.tasteResult?.tasteWeight.spicy = 0.85
    }

    await store.send(.finishButtonTapped) {
      $0.isEditingTaste = false
      $0.editingOrder = nil
      $0.isSubmitting = true
      $0.draft.step = 5
    }

    await store.receive(\.completeOnboardingResponse) {
      $0.isSubmitting = false
    }

    await store.receive(
      .delegate(.completed(finalDraft: store.state.draft))
    )

    #expect(completedDraft.value?.tasteResult?.tasteWeight.spicy == 0.85)
    #expect(completedProfileId.value == OnboardingMapper.defaultProfileId)
  }
}
