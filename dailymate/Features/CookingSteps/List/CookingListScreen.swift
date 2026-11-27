//
//  CookingListScreen.swift
//  dailymate
//

import ComposableArchitecture
import SwiftUI

/// Chế độ "Danh sách": xem tất cả các bước, chạm để đánh dấu xong. Kèm trạng thái tải / lỗi.
struct CookingListScreen: View {
    @Bindable var store: StoreOf<CookingStepsFeature>

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !store.title.isEmpty {
                        Text(store.title)
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(Color.Ghibli.inkDark)
                    }

                    if store.isLoading {
                        CookingLoadingBlock()
                    } else if let error = store.error {
                        CookingErrorBlock(error: error, sourceURL: store.sourceURL) {
                            store.send(.retryTapped)
                        }
                    } else {
                        stepsContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { PaperBackground() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            CookingRoundButton(systemName: "chevron.left", label: "Quay lại") {
                store.send(.backTapped)
            }
            Text("Các bước nấu")
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color.Ghibli.inkDark)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var stepsContent: some View {
        summaryPills

        if store.languageMismatch {
            Text("Hướng dẫn hiện chỉ có bằng tiếng Việt.")
                .font(.footnote)
                .foregroundStyle(CookingPalette.warning)
        }

        progressSection

        Picker("Chế độ xem", selection: $store.isFocusMode.sending(\.setFocusMode)) {
            Text("Danh sách").tag(false)
            Text("Từng bước").tag(true)
        }
        .pickerStyle(.segmented)

        Text("Chạm vào một bước để đánh dấu đã xong.")
            .font(.footnote)
            .foregroundStyle(Color.Ghibli.inkMuted)

        ForEach(store.steps) { step in
            ListStepCard(step: step, isDone: store.done.contains(step.stepNo)) {
                store.send(.toggleStep(step.stepNo), animation: .snappy)
            }
        }

        if !store.done.isEmpty {
            Button("Làm lại từ đầu") { store.send(.resetTapped, animation: .snappy) }
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(6)
        }

        CookingSourceLink(url: store.sourceURL)
    }

    private var summaryPills: some View {
        HStack(spacing: 8) {
            CookingPill(text: "\(store.steps.count) bước", tint: Color.Ghibli.skyDeep)
            if let minutes = store.cookTimeMinutes, minutes > 0 {
                CookingPill(text: "⏱ \(minutes) phút", tint: Color.Ghibli.wood)
            }
            if let method = store.methodLabel {
                CookingPill(text: method, tint: CookingPalette.green)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.allDone ? "🎉 Bạn đã hoàn thành tất cả các bước!" : "Đã xong \(store.done.count)/\(store.steps.count) bước")
                .font(.footnote.weight(.bold))
                .foregroundStyle(store.allDone ? CookingPalette.green : Color.Ghibli.inkLabel)
            ProgressView(value: store.progress)
                .tint(CookingPalette.green)
                .animation(.easeInOut, value: store.progress)
        }
    }
}
