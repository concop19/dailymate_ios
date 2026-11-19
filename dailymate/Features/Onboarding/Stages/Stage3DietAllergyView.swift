//
//  Stage3DietAllergyView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import SwiftUI

struct Stage3DietAllergyView: View {
  @Bindable var store: StoreOf<Stage3DietAllergyFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 26) {
        header
        dietSection
        allergySection
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom) { continueBar }
    .background { OnboardingBackground() }
    .toolbar(.hidden, for: .navigationBar)
    .sheet(
      item: Binding(
        get: { store.activeSheet },
        set: { if $0 == nil { store.send(.sheetDismissed) } }
      )
    ) { sheet in
      AllergyGroupSheetView(store: store, sheet: sheet)
        .presentationDetents(sheet.step == .scopeSelection ? [.height(400), .medium] : [.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(Color(hex: 0xF5EFE2))
    }
  }

  // MARK: - Header

  private var header: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Chế độ ăn & dị ứng")
        .font(.system(.largeTitle, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .fixedSize(horizontal: false, vertical: true)

      MascotBanner(
        message: "Món chứa thứ bạn không ăn được sẽ bị loại hẳn khỏi gợi ý.",
        animationName: "cat_calico",
        mascotSize: 88
      )
    }
  }

  // MARK: - Diet Type

  private var dietSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      OnboardingSectionLabel("Chế độ ăn")

      VStack(spacing: 12) {
        ForEach(DietType.allCases, id: \.self) { diet in
          OnboardingRadioRow(
            emoji: diet.displayEmoji,
            title: diet.displayTitle,
            subtitle: diet.displaySubtitle,
            isSelected: store.dietType == diet
          ) {
            store.send(.dietTypeSelected(diet))
          }
        }
      }
    }
  }

  // MARK: - Allergies

  private var allergySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        OnboardingSectionLabel("Dị ứng / Không ăn được")

        Text("Chạm vào một nhóm để chọn dị ứng cả nhóm hay chỉ vài loại.")
          .font(.subheadline)
          .foregroundStyle(Color.Ghibli.inkMuted)
          .fixedSize(horizontal: false, vertical: true)
      }

      OnboardingFlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
        AllergyChipButton(
          emoji: "✅",
          title: "Không dị ứng gì",
          isSelected: store.noAllergy
        ) {
          store.send(.noAllergyTapped)
        }

        ForEach(AllergyGroup.allCases, id: \.self) { group in
          AllergyChipButton(
            emoji: group.displayEmoji,
            title: group.displayTitle,
            badge: store.badgeByGroup[group],
            isSelected: store.highlightedGroups.contains(group)
          ) {
            store.send(.allergyGroupChipTapped(group))
          }
        }
      }

      if let error = store.allergyError {
        OnboardingErrorText(error)
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

// MARK: - Bottom Sheet (stage3_1 & stage3_2)

private struct AllergyGroupSheetView: View {
  @Bindable var store: StoreOf<Stage3DietAllergyFeature>
  let sheet: Stage3DietAllergyFeature.AllergySheetState
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    Group {
      switch sheet.step {
      case .scopeSelection:
        scopeSelectionContent
      case .ingredientPicker:
        ingredientPickerContent
      }
    }
  }

  // MARK: Step 1 — Scope selection (stage3_1.jpg)

  private var scopeSelectionContent: some View {
    let group = sheet.group
    let isWholeSelected = store.allergyGroups.contains(group)
    let hasPartialSelection = store.allergyItems.contains { $0.group == group }

    return VStack(alignment: .leading, spacing: 18) {
      Text("\(group.displayEmoji) Bạn dị ứng hầu hết \(group.displayLowercaseName) hay chỉ một số loại?")
        .font(.system(.title2, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 12)

      VStack(spacing: 12) {
        scopeOptionCard(
          title: "Hầu hết / tất cả \(group.displayLowercaseName)",
          subtitle: "Loại mọi món có nguyên liệu thuộc nhóm này.",
          isSelected: isWholeSelected
        ) {
          store.send(.sheetAllGroupSelected)
        }

        scopeOptionCard(
          title: "Chỉ một số loại",
          subtitle: "Chọn đúng nguyên liệu bạn bị dị ứng, các loại khác vẫn được gợi ý.",
          isSelected: hasPartialSelection
        ) {
          store.send(.sheetSomeItemsSelected)
        }
      }

      if isWholeSelected || hasPartialSelection {
        Button {
          store.send(.sheetClearGroupTapped)
        } label: {
          Text("Không dị ứng \(group.displayLowercaseName) (bỏ chọn)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.Ghibli.inkMuted)
            .underline()
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 22)
    .padding(.top, 14)
    .padding(.bottom, 20)
  }

  private func scopeOptionCard(
    title: String,
    subtitle: String,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

    return Button(action: action) {
      HStack(alignment: .top, spacing: 14) {
        ZStack {
          Circle()
            .fill(isSelected ? Color.Ghibli.wood : Color.clear)
            .frame(width: 24, height: 24)
            .overlay {
              Circle()
                .strokeBorder(
                  isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.8),
                  lineWidth: 2
                )
            }

          if isSelected {
            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        .padding(.top, 2)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.Ghibli.inkDark)
            .multilineTextAlignment(.leading)

          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(Color.Ghibli.inkMuted)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(16)
      .background(isSelected ? Color(hex: 0xFFF8EA) : Color(hex: 0xFAF6EE), in: shape)
      .overlay {
        shape.strokeBorder(
          isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.45),
          lineWidth: isSelected ? 2 : 1.5
        )
      }
      .contentShape(shape)
    }
    .buttonStyle(.ghibliPress)
  }

  // MARK: Step 2 — Ingredient picker (stage3_2.jpg)

  private var ingredientPickerContent: some View {
    let group = sheet.group
    let selectedIds = Set(sheet.draftSelectedItems.map(\.id))
    let count = sheet.draftSelectedItems.count
    let doneTitle = count == 0
      ? "Xong (chưa chọn loại nào)"
      : "Xong (đã chọn \(count) loại)"

    return VStack(alignment: .leading, spacing: 14) {
      // Top navigation row
      HStack {
        Button {
          isSearchFocused = false
          store.send(.sheetBackToScopeTapped)
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
              .font(.subheadline.weight(.bold))
            Text("Quay lại")
              .font(.subheadline.weight(.bold))
          }
          .foregroundStyle(Color.Ghibli.wood)
        }

        Spacer()

        Text("\(group.displayEmoji) \(group.displayTitle)")
          .font(.system(.title3, design: .serif, weight: .bold))
          .foregroundStyle(Color.Ghibli.inkDark)

        Spacer()

        // Cân bằng chiều ngang với nút Quay lại
        Color.clear.frame(width: 72, height: 1)
      }
      .padding(.top, 12)

      Text("Tick những nguyên liệu bạn bị dị ứng:")
        .font(.subheadline)
        .foregroundStyle(Color.Ghibli.inkBody)

      // Search box
      TextField(
        "Tìm nguyên liệu",
        text: Binding(
          get: { sheet.searchQuery },
          set: { store.send(.sheetSearchQueryChanged($0)) }
        ),
        prompt: ghibliPrompt("Tìm nguyên liệu (vd: \(group.searchPlaceholderExample))")
      )
      .focused($isSearchFocused)
      .ghibliInputContainer(isFocused: isSearchFocused)

      // Ingredients list
      if sheet.isLoadingIngredients {
        VStack(spacing: 12) {
          Spacer()
          ProgressView()
            .tint(Color.Ghibli.wood)
          Text("Đang tải danh sách nguyên liệu...")
            .font(.subheadline)
            .foregroundStyle(Color.Ghibli.inkMuted)
          Spacer()
        }
        .frame(maxWidth: .infinity)
      } else if let loadError = sheet.loadError {
        VStack(spacing: 12) {
          Spacer()
          OnboardingErrorText(loadError)
          Button("Thử lại") {
            store.send(.retryLoadIngredientsTapped)
          }
          .font(.subheadline.weight(.bold))
          .foregroundStyle(Color.Ghibli.wood)
          Spacer()
        }
        .frame(maxWidth: .infinity)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(store.filteredSheetIngredients) { item in
              ingredientRow(
                item: item,
                isChecked: selectedIds.contains(item.id)
              )
            }
          }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
      }

      GhibliPrimaryButton(title: doneTitle, color: Color.Ghibli.wood) {
        isSearchFocused = false
        store.send(.sheetDoneButtonTapped)
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, 8)
    .padding(.bottom, 16)
  }

  private func ingredientRow(item: AllergyItem, isChecked: Bool) -> some View {
    let boxShape = RoundedRectangle(cornerRadius: 7, style: .continuous)

    return Button {
      store.send(.sheetIngredientToggled(item))
    } label: {
      HStack(spacing: 14) {
        ZStack {
          boxShape
            .fill(isChecked ? Color.Ghibli.wood : Color(hex: 0xFAF6EE))
            .frame(width: 24, height: 24)
            .overlay {
              boxShape.strokeBorder(
                isChecked ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.75),
                lineWidth: 1.8
              )
            }

          if isChecked {
            Image(systemName: "checkmark")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.white)
          }
        }

        Text(item.name)
          .font(.body)
          .foregroundStyle(Color.Ghibli.inkDark)

        Spacer()
      }
      .padding(.vertical, 13)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(Color.Ghibli.straw.opacity(0.16))
        .frame(height: 1)
    }
  }
}

#Preview {
  NavigationStack {
    Stage3DietAllergyView(
      store: Store(initialState: Stage3DietAllergyFeature.State()) {
        Stage3DietAllergyFeature()
      } withDependencies: {
        $0.onboardingAPIClient.fetchAllergyIngredients = { group, _ in
          [
            AllergyItem(id: 1, name: "tôm", group: group),
            AllergyItem(id: 2, name: "tôm thẻ loại to", group: group),
            AllergyItem(id: 3, name: "nước mắm", group: group),
            AllergyItem(id: 4, name: "mực", group: group),
            AllergyItem(id: 5, name: "cua", group: group),
          ]
        }
      }
    )
  }
}
