//
//  Stage5TasteSummaryView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Lottie
import SwiftUI

struct Stage5TasteSummaryView: View {
  let store: StoreOf<Stage5TasteSummaryFeature>

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        mascotAndTitleSection
        tasteBarsCard
        editTasteButton
        summaryTagsRow

        if let error = store.errorMessage {
          ErrorText(error)
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 4)
      .padding(.bottom, 24)
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom) { finishBar }
    .background { PaperBackground() }
    .toolbar(.hidden, for: .navigationBar)
  }

  // MARK: - Top Mascot & Headline

  private var mascotAndTitleSection: some View {
    VStack(spacing: 12) {
      LottieView(animation: .named("Cat Pookie"))
        .playing(loopMode: .loop)
        .resizable()
        .scaledToFit()
        .frame(width: 132, height: 132)
        .accessibilityHidden(true)

      Text("Khẩu vị của bạn")
        .font(.system(.largeTitle, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .multilineTextAlignment(.center)

      Text(store.topThreeHeadline)
        .font(.system(.title3, design: .serif, weight: .bold))
        .foregroundStyle(Color.Ghibli.inkDark)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      Text(store.sourceSubtitle)
        .font(.subheadline)
        .foregroundStyle(Color.Ghibli.inkMuted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - 7 Taste Bars Card

  private var tasteBarsCard: some View {
    let cardShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    return VStack(spacing: 15) {
      ForEach(store.dimensionRows) { row in
        TasteDimensionBarRow(
          row: row,
          isEditing: store.isEditingTaste
        ) { newValue in
          store.send(.tasteValueChanged(row.dimension, newValue))
        }
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 20)
    .background(Color(hex: 0xFAF5EA), in: cardShape)
    .overlay {
      cardShape.strokeBorder(Color.Ghibli.straw.opacity(0.65), lineWidth: 1.6)
    }
    .shadow(color: Color.Ghibli.wood.opacity(0.08), radius: 8, x: 0, y: 4)
  }

  // MARK: - Edit Taste Dashed Button

  private var editTasteButton: some View {
    let buttonShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    return Button {
      store.send(.toggleEditTasteTapped)
    } label: {
      HStack(spacing: 8) {
        Text(store.isEditingTaste ? "✅" : "🎛️")
          .font(.subheadline)
        Text(store.isEditingTaste ? "Xong chỉnh vị giác" : "Chỉnh lại thanh vị giác")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(Color.Ghibli.inkDark)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        store.isEditingTaste ? Color(hex: 0xFFF8EA) : Color.clear,
        in: buttonShape
      )
      .overlay {
        buttonShape.strokeBorder(
          store.isEditingTaste ? Color.Ghibli.wood : Color.Ghibli.straw,
          style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
        )
      }
    }
    .buttonStyle(.ghibliPress)
  }

  // MARK: - Profile Summary Pills

  private var summaryTagsRow: some View {
    OnboardingFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
      summaryPill(
        emoji: store.regionSummaryEmoji,
        title: store.regionSummaryTitle,
        backgroundColor: Color(hex: 0xECE3D2),
        textColor: Color.Ghibli.inkDark
      )

      summaryPill(
        emoji: store.dietSummaryEmoji,
        title: store.dietSummaryTitle,
        backgroundColor: Color(hex: 0xECE3D2),
        textColor: Color.Ghibli.inkDark
      )

      summaryPill(
        emoji: store.hasNoAllergy ? nil : "⚠️",
        title: store.allergySummaryTitle,
        backgroundColor: store.hasNoAllergy ? Color(hex: 0xDDF0E9) : Color(hex: 0xF5E3DC),
        textColor: store.hasNoAllergy ? Color(hex: 0x265C4B) : Color(hex: 0x7A3A26)
      )
    }
  }

  private func summaryPill(
    emoji: String?,
    title: String,
    backgroundColor: Color,
    textColor: Color
  ) -> some View {
    HStack(spacing: 6) {
      if let emoji, !emoji.isEmpty {
        Text(emoji)
          .font(.footnote)
      }
      Text(title)
        .font(.footnote.weight(.bold))
        .foregroundStyle(textColor)
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 8)
    .background(backgroundColor, in: .capsule)
  }

  // MARK: - Bottom CTA

  private var finishBar: some View {
    GhibliPrimaryButton(
      title: "Bắt đầu khám phá món ăn",
      color: Color.Ghibli.wood,
      isLoading: store.isSubmitting
    ) {
      store.send(.finishButtonTapped)
    }
    .padding(.horizontal, 24)
    .padding(.top, 12)
    .padding(.bottom, 8)
    .background(Color.Ghibli.cream.opacity(0.95))
    .overlay(alignment: .top) {
      Rectangle().fill(Color.Ghibli.straw.opacity(0.25)).frame(height: 1)
    }
  }
}

// MARK: - Single Taste Bar Row

private struct TasteDimensionBarRow: View {
  let row: Stage5TasteSummaryFeature.DimensionRow
  let isEditing: Bool
  let onChange: (Double) -> Void

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Text(row.dimension.displayEmoji)
          .font(.system(size: 18))

        Text(row.dimension.displayTitle)
          .font(row.isTopThree ? .body.weight(.bold) : .body)
          .foregroundStyle(Color.Ghibli.inkDark)
          .lineLimit(1)
      }
      .frame(width: 112, alignment: .leading)

      GeometryReader { proxy in
        let width = max(proxy.size.width, 1)
        let fillWidth = max(12, width * CGFloat(row.value))
        let fillColor = row.isTopThree ? Color.Ghibli.wood : Color.Ghibli.straw

        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color(hex: 0xE8DEC9))
            .frame(height: 14)

          Capsule()
            .fill(fillColor)
            .frame(width: fillWidth, height: 14)

          if isEditing {
            Circle()
              .fill(Color.white)
              .frame(width: 22, height: 22)
              .overlay {
                Circle().strokeBorder(fillColor, lineWidth: 2.5)
              }
              .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
              .offset(x: min(max(fillWidth - 11, 0), width - 22))
          }
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { gesture in
              guard isEditing else { return }
              let ratio = Double(gesture.location.x / width)
              onChange(min(max(ratio, 0), 1))
            }
        )
      }
      .frame(height: 22)

      Text(row.percentageText)
        .font(row.isTopThree ? .body.weight(.bold) : .body)
        .foregroundStyle(Color.Ghibli.inkDark)
        .monospacedDigit()
        .frame(width: 46, alignment: .trailing)
    }
  }
}

#Preview {
  NavigationStack {
    Stage5TasteSummaryView(
      store: Store(
        initialState: Stage5TasteSummaryFeature.State(
          draft: OnboardingDraft(
            nation: .vietnam,
            homeRegion: .central,
            dietType: .omnivore,
            noAllergy: true,
            tasteResult: TasteResult(
              tasteWeight: TasteVector(
                sweet: 0.31,
                sour: 0.31,
                salty: 0.54,
                bitter: 0.25,
                umami: 0.52,
                spicy: 0.51,
                astringent: 0.30
              ),
              source: .flashcards,
              likedDishIds: ["1", "2"],
              dislikedDishIds: ["3"]
            )
          )
        )
      ) {
        Stage5TasteSummaryFeature()
      }
    )
  }
}
