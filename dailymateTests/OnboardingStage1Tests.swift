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

  @Test("Chưa nhập năm sinh → kitten / tabby_girl")
  func noBirthYear() {
    #expect(AnimationPlan.resolve(gender: nil, birthYear: nil, currentYear: year) == .kitten)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: nil, currentYear: year) == .kitten)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: nil, currentYear: year) == .tabbyGirl)
  }

  @Test("Ánh xạ đủ 18 avatar theo 2 giới tính & 8 nhóm tuổi")
  func allGroups() {
    let cases: [(Gender?, Int, AnimationPlan)] = [
      (.male, 2022, .boyToddlerBong), (.female, 2022, .girlToddlerSua),
      (.male, 2016, .boyChildButChi), (.female, 2016, .girlChildNo),
      (.male, 2010, .boyYouthBeat),   (.female, 2010, .girlYouthMay),
      (.male, 2000, .brother),        (.female, 2000, .sister),
      (.male, 1990, .manAdultMoka),   (.female, 1990, .womanAdultLa),
      (.male, 1975, .father),         (.female, 1975, .mother),
      (.male, 1960, .manSeniorTra),   (.female, 1960, .womanSeniorMai),
      (.male, 1945, .grandpa),        (.female, 1945, .grandma),
      (nil, 1990, .kitten),
    ]
    for (gender, birthYear, expected) in cases {
      #expect(AnimationPlan.resolve(gender: gender, birthYear: birthYear, currentYear: year) == expected)
    }
  }

  @Test("Ngưỡng biên 5/6, 12/13, 18/19, 29/30, 44/45, 59/60, 74/75")
  func boundaries() {
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 5, currentYear: year) == .boyToddlerBong)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 6, currentYear: year) == .boyChildButChi)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 12, currentYear: year) == .girlChildNo)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 13, currentYear: year) == .girlYouthMay)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 18, currentYear: year) == .boyYouthBeat)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 19, currentYear: year) == .brother)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 29, currentYear: year) == .sister)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 30, currentYear: year) == .womanAdultLa)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 44, currentYear: year) == .manAdultMoka)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 45, currentYear: year) == .father)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 59, currentYear: year) == .mother)
    #expect(AnimationPlan.resolve(gender: .female, birthYear: year - 60, currentYear: year) == .womanSeniorMai)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 74, currentYear: year) == .manSeniorTra)
    #expect(AnimationPlan.resolve(gender: .male, birthYear: year - 75, currentYear: year) == .grandpa)
  }
}

@MainActor
@Suite("Onboarding — Stage 1")
struct OnboardingStage1Tests {
  @Test("Năm sinh: chỉ nhận giá trị trong khoảng hợp lệ minBirthYear...maxBirthYear")
  func birthYearValidation() async {
    let store = TestStore(initialState: Stage1PersonalFeature.State(currentYear: 2026)) {
      Stage1PersonalFeature()
    }

    await store.send(.birthYearSelect(2015)) {
      $0.birthYear = 2015
    }
    #expect(store.state.birthYear == 2015)
    #expect(store.state.birthYearError == nil)

    await store.send(.birthYearSelect(1800)) {
      $0.birthYear = nil
      $0.showsValidation = true
    }
    #expect(store.state.birthYear == nil)
    #expect(store.state.birthYearError != nil)

    await store.send(.birthYearSelect(2025))
    #expect(store.state.birthYear == nil) // < 4 tuổi
    #expect(store.state.birthYearError != nil)
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
    await store.send(.stage1(.birthYearSelect(2015))) {
      $0.stage1.birthYear = 2015
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
    let completedProfileId = LockIsolated<String?>("unset")
    let savedProfileId = "11111111-1111-1111-1111-111111111111"

    let store = TestStore(
      initialState: Stage5TasteSummaryFeature.State(draft: initialDraft)
    ) {
      Stage5TasteSummaryFeature()
    } withDependencies: {
      $0.onboardingSupabaseClient.completeOnboarding = { draft, existingProfileId in
        completedDraft.setValue(draft)
        completedProfileId.setValue(existingProfileId)
        return savedProfileId
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
      var expectedWeight = initialVector
      expectedWeight.spicy = 0.85
      $0.draft.tasteResult = TasteResult(
        tasteWeight: expectedWeight,
        source: .flashcards,
        likedDishIds: ["dish_1"],
        dislikedDishIds: ["dish_2"]
      )
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
      .delegate(.completed(finalDraft: store.state.draft, profileId: savedProfileId))
    )

    #expect(completedDraft.value?.tasteResult?.tasteWeight.spicy == 0.85)
    // Hồ sơ mới → không có existingProfileId (client sẽ insert user_profiles).
    #expect(completedProfileId.value == nil)
  }

  @Test("Lỗi giới hạn 5 hồ sơ → hiện thông báo thân thiện, không hoàn tất")
  func profileLimitReached() async {
    let store = TestStore(
      initialState: Stage5TasteSummaryFeature.State(draft: OnboardingDraft(step: 4))
    ) {
      Stage5TasteSummaryFeature()
    } withDependencies: {
      $0.onboardingSupabaseClient.completeOnboarding = { _, _ in
        throw OnboardingSupabaseError.profileLimitReached
      }
    }
    store.exhaustivity = .off

    await store.send(.finishButtonTapped)
    await store.receive(\.completeOnboardingResponse) {
      $0.isSubmitting = false
      $0.errorMessage = OnboardingSupabaseError.profileLimitReached.errorDescription
    }
  }
}

@Suite("OnboardingMapper — schema user_profiles mới")
struct OnboardingMapperSchemaTests {
  @Test("Dị ứng nằm trong data.allergies, patch không ghi đè thông tin định danh, không có body_metrics")
  func profileDataShape() throws {
    let draft = OnboardingDraft(
      birthYear: 2000,
      allergyGroups: [.seafood, .seafood],
      allergyItems: [AllergyItem(id: 7, name: "Tôm", group: .seafood)]
    )
    let insertData = OnboardingMapper.toProfileData(draft: draft, includeIdentity: true, displayName: "Mạnh")
    #expect(insertData.displayName == "Mạnh")
    #expect(insertData.allergies?.map(\.allergyKey) == ["seafood", "7"])
    #expect(insertData.onboardingCompletedAt != nil)

    let patchData = OnboardingMapper.toProfileData(draft: draft, includeIdentity: false)
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(patchData)) as? [String: Any]
    #expect(json?["displayName"] == nil)
    #expect(json?["isDefault"] == nil)
    #expect(json?["body_metrics"] == nil)
    #expect((json?["allergies"] as? [Any])?.count == 2)
  }

  @Test("Không dị ứng → gửi mảng rỗng để thay toàn bộ allergies cũ")
  func noAllergySendsEmptyArray() {
    let draft = OnboardingDraft(allergyGroups: [.beef], noAllergy: true)
    #expect(OnboardingMapper.toProfileData(draft: draft, includeIdentity: false).allergies == [])
  }

  @Test("Bootstrap: ưu tiên active_profile_id, sau đó sort_order nhỏ nhất")
  func selectStartupRow() throws {
    let json = """
    {"settings":{"active_profile_id":"22222222-2222-2222-2222-222222222222"},
     "profiles":[
       {"profile_id":"11111111-1111-1111-1111-111111111111","sort_order":0,"data":{"displayName":"A"}},
       {"profile_id":"22222222-2222-2222-2222-222222222222","sort_order":1,"data":{"displayName":"B"}}
     ],
     "server_time":"2026-11-20T00:00:00Z"}
    """
    let bootstrap = try JSONDecoder().decode(BootstrapResponseDTO.self, from: Data(json.utf8))
    #expect(OnboardingMapper.selectStartupRow(bootstrap)?.data.displayName == "B")

    let noActive = try JSONDecoder().decode(
      BootstrapResponseDTO.self,
      from: Data(json.replacingOccurrences(of: "22222222-2222-2222-2222-222222222222\"}", with: "x\"}").utf8)
    )
    #expect(OnboardingMapper.selectStartupRow(noActive)?.data.displayName == "A")

    let empty = try JSONDecoder().decode(BootstrapResponseDTO.self, from: Data(#"{"settings":{},"profiles":[]}"#.utf8))
    #expect(OnboardingMapper.selectStartupRow(empty) == nil)
  }
}

@MainActor
@Suite("AppFeature — khởi động với cache / mất mạng")
struct AppStartupTests {
  struct Offline: Error {}

  private static let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!

  private static var completedProfile: UserProfile {
    var profile = OnboardingMapper.defaultStartupProfile()
    profile.profileId = "11111111-1111-1111-1111-111111111111"
    profile.isPersisted = true
    profile.onboardingCompletedAt = Date(timeIntervalSince1970: 1_700_000_000)
    return profile
  }

  @Test("Có cache + mất mạng → vào Home ngay, không bị đẩy vào onboarding")
  func cachedOffline() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.localClient.loadStartupProfile = { _ in Self.completedProfile }
      $0.onboardingSupabaseClient.loadStartupProfile = { throw Offline() }
    }

    await store.send(.authStateChanged(userId: Self.userId)) {
      $0.isCheckingSession = false
      $0.isAuthenticated = true
      $0.isLoadingProfile = false
    }
    await store.receive(\.startupProfileLoaded)
    #expect(store.state.onboarding == nil)
  }

  @Test("Không cache + mất mạng → không kẹt màn chờ, không ép onboarding")
  func noCacheOffline() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.localClient.loadStartupProfile = { _ in nil }
      $0.onboardingSupabaseClient.loadStartupProfile = { throw Offline() }
    }

    await store.send(.authStateChanged(userId: Self.userId)) {
      $0.isCheckingSession = false
      $0.isAuthenticated = true
      $0.isLoadingProfile = true
    }
    await store.receive(\.startupProfileLoaded) {
      $0.isLoadingProfile = false
    }
    #expect(store.state.onboarding == nil)
  }

  @Test("User mới (server chưa có hồ sơ) → vào onboarding, không cache hồ sơ tạm")
  func newUserGoesToOnboarding() async {
    let saved = LockIsolated(0)
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.localClient.loadStartupProfile = { _ in nil }
      $0.localClient.saveStartupProfile = { _, _ in saved.withValue { $0 += 1 } }
      $0.localClient.loadDraft = { _, _ in nil }
      $0.onboardingSupabaseClient.loadStartupProfile = { OnboardingMapper.defaultStartupProfile() }
    }
    store.exhaustivity = .off

    await store.send(.authStateChanged(userId: Self.userId))
    await store.receive(\.startupProfileLoaded)
    #expect(store.state.onboarding?.profile.isPersisted == false)
    #expect(saved.value == 0)
  }
}
