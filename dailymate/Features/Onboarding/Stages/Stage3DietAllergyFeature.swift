//
//  Stage3DietAllergyFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

/// Stage 3 — Chế độ ăn & Dị ứng ("Chế độ ăn & dị ứng").
@Reducer
struct Stage3DietAllergyFeature {
  struct AllergySheetState: Equatable, Identifiable, Sendable {
    enum Step: Equatable, Sendable {
      case scopeSelection
      case ingredientPicker
    }

    var id: AllergyGroup { group }
    let group: AllergyGroup
    var step: Step = .scopeSelection
    var searchQuery: String = ""
    var draftSelectedItems: [AllergyItem] = []
    var isLoadingIngredients = false
    var loadError: String? = nil
  }

  @ObservableState
  struct State: Equatable {
    var dietType: DietType
    var noAllergy: Bool
    var allergyGroups: [AllergyGroup]
    var allergyItems: [AllergyItem]
    var activeSheet: AllergySheetState? = nil
    var cachedIngredientsByGroup: [AllergyGroup: [AllergyItem]] = [:]
    var language: String = "vi"
    var showsValidation = false
    var shakeTrigger = 0

    init(
      dietType: DietType = .omnivore,
      noAllergy: Bool = false,
      allergyGroups: [AllergyGroup] = [],
      allergyItems: [AllergyItem] = [],
      language: String = "vi"
    ) {
      self.dietType = dietType
      self.noAllergy = noAllergy
      self.allergyGroups = allergyGroups
      self.allergyItems = allergyItems
      self.language = language
    }

    init(draft: OnboardingDraft, language: String = "vi") {
      self.init(
        dietType: draft.dietType,
        noAllergy: draft.noAllergy,
        allergyGroups: draft.allergyGroups,
        allergyItems: draft.allergyItems,
        language: language
      )
    }

    // MARK: Derived

    /// Đã xác nhận trạng thái dị ứng (chọn "Không dị ứng gì" hoặc chọn ít nhất 1 nhóm/nguyên liệu).
    var canContinue: Bool {
      noAllergy || !allergyGroups.isEmpty || !allergyItems.isEmpty
    }

    var allergyError: String? {
      guard showsValidation, !canContinue else { return nil }
      return "Vui lòng chọn nhóm dị ứng hoặc bấm \"Không dị ứng gì\""
    }

    func isWholeGroupSelected(_ group: AllergyGroup) -> Bool {
      allergyGroups.contains(group)
    }

    func selectedItems(for group: AllergyGroup) -> [AllergyItem] {
      allergyItems.filter { $0.group == group }
    }

    func isGroupHighlighted(_ group: AllergyGroup) -> Bool {
      isWholeGroupSelected(group) || !selectedItems(for: group).isEmpty
    }

    func badgeText(for group: AllergyGroup) -> String? {
      if isWholeGroupSelected(group) {
        return "Tất cả"
      }
      let count = selectedItems(for: group).count
      return count > 0 ? "\(count)" : nil
    }

    /// Map badge theo từng nhóm để truy cập qua `@dynamicMemberLookup` trên `Store`.
    var badgeByGroup: [AllergyGroup: String] {
      var result: [AllergyGroup: String] = [:]
      for group in AllergyGroup.allCases {
        if let badge = badgeText(for: group) {
          result[group] = badge
        }
      }
      return result
    }

    /// Tập các nhóm đang được chọn (cả nhóm hoặc một số loại) để truy cập qua `Store`.
    var highlightedGroups: Set<AllergyGroup> {
      Set(AllergyGroup.allCases.filter { isGroupHighlighted($0) })
    }

    /// Danh sách nguyên liệu hiển thị trong Bottom Sheet Bước 2 (đã lọc theo `searchQuery`).
    var filteredSheetIngredients: [AllergyItem] {
      guard let sheet = activeSheet else { return [] }
      let allItems = cachedIngredientsByGroup[sheet.group] ?? []
      let query = Self.normalizedSearchText(sheet.searchQuery)
      guard !query.isEmpty else { return allItems }
      return allItems.filter { item in
        Self.normalizedSearchText(item.name).contains(query)
      }
    }

    private static func normalizedSearchText(_ text: String) -> String {
      text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
        .replacingOccurrences(of: "đ", with: "d")
        .replacingOccurrences(of: "Đ", with: "d")
    }
  }

  enum Action: Equatable {
    case dietTypeSelected(DietType)
    case noAllergyTapped
    case allergyGroupChipTapped(AllergyGroup)
    case sheetDismissed
    case sheetAllGroupSelected
    case sheetSomeItemsSelected
    case sheetClearGroupTapped
    case sheetBackToScopeTapped
    case sheetSearchQueryChanged(String)
    case sheetIngredientToggled(AllergyItem)
    case sheetDoneButtonTapped
    case retryLoadIngredientsTapped
    case allergyIngredientsLoaded(group: AllergyGroup, Result<[AllergyItem], EquatableError>)
    case continueButtonTapped
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case completed(
        dietType: DietType,
        noAllergy: Bool,
        allergyGroups: [AllergyGroup],
        allergyItems: [AllergyItem]
      )
    }
  }

  struct EquatableError: Error, Equatable, Sendable {
    let message: String
  }

  private enum CancelID {
    case fetchIngredients
  }

  @Dependency(\.onboardingAPIClient) var onboardingAPIClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .dietTypeSelected(dietType):
        state.dietType = dietType
        return .none

      case .noAllergyTapped:
        state.noAllergy.toggle()
        if state.noAllergy {
          state.allergyGroups.removeAll()
          state.allergyItems.removeAll()
          state.showsValidation = false
        }
        return .none

      case let .allergyGroupChipTapped(group):
        let existingItems = state.selectedItems(for: group)
        state.activeSheet = AllergySheetState(
          group: group,
          step: .scopeSelection,
          searchQuery: "",
          draftSelectedItems: existingItems
        )
        return .none

      case .sheetDismissed:
        state.activeSheet = nil
        return .cancel(id: CancelID.fetchIngredients)

      case .sheetAllGroupSelected:
        guard let group = state.activeSheet?.group else { return .none }
        if !state.allergyGroups.contains(group) {
          state.allergyGroups.append(group)
        }
        state.allergyItems.removeAll { $0.group == group }
        state.noAllergy = false
        state.showsValidation = false
        state.activeSheet = nil
        return .cancel(id: CancelID.fetchIngredients)

      case .sheetSomeItemsSelected:
        guard var sheet = state.activeSheet else { return .none }
        let group = sheet.group
        sheet.step = .ingredientPicker
        sheet.loadError = nil

        if state.cachedIngredientsByGroup[group] != nil {
          sheet.isLoadingIngredients = false
          state.activeSheet = sheet
          return .none
        }

        sheet.isLoadingIngredients = true
        state.activeSheet = sheet
        return fetchIngredientsEffect(group: group, language: state.language)

      case .sheetClearGroupTapped:
        guard let group = state.activeSheet?.group else { return .none }
        state.allergyGroups.removeAll { $0 == group }
        state.allergyItems.removeAll { $0.group == group }
        state.activeSheet = nil
        return .cancel(id: CancelID.fetchIngredients)

      case .sheetBackToScopeTapped:
        state.activeSheet?.step = .scopeSelection
        state.activeSheet?.searchQuery = ""
        return .none

      case let .sheetSearchQueryChanged(query):
        state.activeSheet?.searchQuery = query
        return .none

      case let .sheetIngredientToggled(item):
        guard var sheet = state.activeSheet else { return .none }
        if let index = sheet.draftSelectedItems.firstIndex(where: { $0.id == item.id }) {
          sheet.draftSelectedItems.remove(at: index)
        } else {
          let taggedItem = AllergyItem(id: item.id, name: item.name, group: sheet.group)
          sheet.draftSelectedItems.append(taggedItem)
        }
        state.activeSheet = sheet
        return .none

      case .sheetDoneButtonTapped:
        guard let sheet = state.activeSheet else { return .none }
        let group = sheet.group
        state.allergyGroups.removeAll { $0 == group }
        state.allergyItems.removeAll { $0.group == group }
        state.allergyItems.append(contentsOf: sheet.draftSelectedItems)

        if !sheet.draftSelectedItems.isEmpty {
          state.noAllergy = false
          state.showsValidation = false
        }
        state.activeSheet = nil
        return .cancel(id: CancelID.fetchIngredients)

      case .retryLoadIngredientsTapped:
        guard var sheet = state.activeSheet else { return .none }
        sheet.isLoadingIngredients = true
        sheet.loadError = nil
        state.activeSheet = sheet
        return fetchIngredientsEffect(group: sheet.group, language: state.language)

      case let .allergyIngredientsLoaded(group, .success(items)):
        let tagged = items.map { AllergyItem(id: $0.id, name: $0.name, group: group) }
        state.cachedIngredientsByGroup[group] = tagged
        if state.activeSheet?.group == group {
          state.activeSheet?.isLoadingIngredients = false
          state.activeSheet?.loadError = nil
        }
        return .none

      case let .allergyIngredientsLoaded(group, .failure(error)):
        if state.activeSheet?.group == group {
          state.activeSheet?.isLoadingIngredients = false
          state.activeSheet?.loadError = error.message
        }
        return .none

      case .continueButtonTapped:
        guard state.canContinue else {
          state.showsValidation = true
          state.shakeTrigger += 1
          return .none
        }
        return .send(
          .delegate(
            .completed(
              dietType: state.dietType,
              noAllergy: state.noAllergy,
              allergyGroups: state.allergyGroups,
              allergyItems: state.allergyItems
            )
          )
        )

      case .delegate:
        return .none
      }
    }
  }

  private func fetchIngredientsEffect(
    group: AllergyGroup,
    language: String
  ) -> Effect<Action> {
    let apiClient = self.onboardingAPIClient
    return .run { send in
      do {
        let items = try await apiClient.fetchAllergyIngredients(group, language)
        await send(.allergyIngredientsLoaded(group: group, .success(items)))
      } catch {
        await send(
          .allergyIngredientsLoaded(
            group: group,
            .failure(EquatableError(message: error.localizedDescription))
          )
        )
      }
    }
    .cancellable(id: CancelID.fetchIngredients, cancelInFlight: true)
  }
}

// MARK: - DietType & AllergyGroup UI Metadata

extension DietType {
  var displayTitle: String {
    switch self {
    case .omnivore: "Ăn mặn"
    case .vegetarian: "Ăn chay"
    case .vegan: "Thuần chay"
    }
  }

  var displaySubtitle: String {
    switch self {
    case .omnivore: "Ăn được cả thịt, cá, trứng, sữa"
    case .vegetarian: "Không thịt cá, vẫn dùng trứng sữa"
    case .vegan: "Hoàn toàn từ thực vật"
    }
  }

  var displayEmoji: String {
    switch self {
    case .omnivore: "man"
    case .vegetarian: "chay"
    case .vegan: "thuan_chay"
    }
  }
}

extension AllergyGroup {
  var displayTitle: String {
    switch self {
    case .seafood: "Hải sản"
    case .fish: "Cá"
    case .beef: "Thịt bò"
    case .pork: "Thịt heo"
    case .poultry: "gia cầm"
    case .legumeNut: "Đậu & hạt"
    case .dairyEgg: "Sữa & trứng"
    case .vegetable: "Rau củ"
    case .gluten: "Gluten / Lúa mì"
    }
  }

  var displayLowercaseName: String {
    displayTitle.lowercased()
  }

  var displayEmoji: String {
    switch self {
    case .seafood: "🦐"
    case .fish: "🐟"
    case .beef: "🐄"
    case .pork: "🐖"
    case .poultry: "🐔"
    case .legumeNut: "🥜"
    case .dairyEgg: "🥛"
    case .vegetable: "🥬"
    case .gluten: "🌾"
    }
  }

  var searchPlaceholderExample: String {
    switch self {
    case .seafood: "tôm, cua..."
    case .fish: "cá lóc, cá ngừ..."
    case .beef: "thịt bò, gân bò..."
    case .pork: "thịt ba chỉ, sườn..."
    case .legumeNut: "đậu phộng, mè..."
    case .poultry : "chicken"
    case .dairyEgg: "trứng gà, sữa tươi..."
    case .vegetable: "cà tím, măng..."
    case .gluten: "bột mì, mì sợi..."
    }
  }
}
