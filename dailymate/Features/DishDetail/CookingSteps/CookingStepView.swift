//
//  CookingStepView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import Lottie
import SwiftUI

private enum CookingPalette {
    static let cardCream = Color(hex: 0xFBF5EA)
    static let peachPill = Color(hex: 0xF6D9C2)
    static let terracotta = Color(hex: 0xB06A45)
    static let softButton = Color(hex: 0xEFE3D0)
    static let dotIdle = Color(hex: 0xEAD9C2)
    static let green = Color(hex: 0x4E9A68)
    static let doneFill = Color(hex: 0xE9F6EC)
    static let warning = Color(hex: 0x8A5D00)
}

/// Số chấm tối đa ở thanh dưới; nhiều bước hơn thì hiện "n / tổng".
private let maxDots = 10

struct CookingStepView: View {
    @Bindable var store: StoreOf<CookingStepsFeature>
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            if store.showsFocusScreen {
                CookingFocusView(store: store)
                    .transition(.opacity)
            } else {
                listScreen
                    .transition(.opacity)
            }

            if store.showFinishPopup {
                finishPopup
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.showsFocusScreen)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.showFinishPopup)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - List mode / loading / error

    private var listScreen: some View {
        VStack(spacing: 0) {
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

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !store.title.isEmpty {
                        Text(store.title)
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(Color.Ghibli.inkDark)
                    }

                    if store.isLoading {
                        loadingBlock
                    } else if let error = store.error {
                        errorBlock(error)
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
        .background { OnboardingBackground() }
    }

    private var loadingBlock: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.Ghibli.wood)
                .controlSize(.large)
            Text("Đang tải các bước nấu…")
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func errorBlock(_ error: CookingStepsFeature.StepsError) -> some View {
        VStack(spacing: 10) {
            LottieView(animation: .named("cat_gosh"))
                .playing(loopMode: .loop)
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
            Text(error.title)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color.Ghibli.inkDark)
                .multilineTextAlignment(.center)
            Text(error.message)
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
                .multilineTextAlignment(.center)
            if error.canRetry {
                GhibliPrimaryButton(title: "Thử lại", icon: "arrow.clockwise") {
                    store.send(.retryTapped)
                }
                .padding(.top, 6)
            }
            sourceLink
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var stepsContent: some View {
        HStack(spacing: 8) {
            CookingPill(text: "\(store.steps.count) bước", tint: Color.Ghibli.skyDeep)
            if let minutes = store.cookTimeMinutes, minutes > 0 {
                CookingPill(text: "⏱ \(minutes) phút", tint: Color.Ghibli.wood)
            }
            if let method = store.methodLabel {
                CookingPill(text: method, tint: CookingPalette.green)
            }
        }

        if store.languageMismatch {
            Text("Hướng dẫn hiện chỉ có bằng tiếng Việt.")
                .font(.footnote)
                .foregroundStyle(CookingPalette.warning)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text(store.allDone ? "🎉 Bạn đã hoàn thành tất cả các bước!" : "Đã xong \(store.done.count)/\(store.steps.count) bước")
                .font(.footnote.weight(.bold))
                .foregroundStyle(store.allDone ? CookingPalette.green : Color.Ghibli.inkLabel)
            ProgressView(value: store.progress)
                .tint(CookingPalette.green)
                .animation(.easeInOut, value: store.progress)
        }

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

        sourceLink
    }

    @ViewBuilder
    private var sourceLink: some View {
        if let url = store.sourceURL {
            Button {
                openURL(url)
            } label: {
                Label("Xem công thức gốc", systemImage: "link")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.skyDeep)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Finish popup

    private var finishPopup: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { store.send(.finishPopupDismissed) }

            VStack(spacing: 14) {
                LottieView(animation: .named("Dance cat"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                Text("Hoàn thành rồi! 🎉")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                Text("Bạn đã nấu xong món \"\(store.title)\". Chúc bạn ăn ngon miệng nha!")
                    .font(.subheadline)
                    .foregroundStyle(Color.Ghibli.inkBody)
                    .multilineTextAlignment(.center)
                GhibliPrimaryButton(title: "Xong", icon: "checkmark", color: CookingPalette.green) {
                    store.send(.finishConfirmed)
                }
                Button("Xem lại các bước") { store.send(.finishPopupDismissed) }
                    .font(.subheadline)
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }
            .padding(24)
            .background(CookingPalette.cardCream, in: .rect(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28).strokeBorder(Color.Ghibli.straw.opacity(0.6), lineWidth: 1)
            }
            .shadow(color: Color.Ghibli.wood.opacity(0.3), radius: 16, y: 8)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Focus mode (nền bếp + Lottie mèo theo loại thao tác)

private struct CookingFocusView: View {
    @Bindable var store: StoreOf<CookingStepsFeature>
    @State private var direction: Int = 1

    var body: some View {
        VStack(spacing: 0) {
                topBar

                ZStack {
                    if let step = store.currentStep {
                        stepPage(step)
                            .id(store.focusIndex)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)
                                )
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(swipeGesture)

                bottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ảnh nền đặt ở .background để không làm phình layout (scaledToFill trong ZStack gây vòng lặp layout).
        .background {
            Image("kitche_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            CookingRoundButton(systemName: "chevron.left", label: "Quay lại") {
                store.send(.backTapped)
            }
            Spacer()
            CookingRoundButton(systemName: "list.bullet", label: "Xem dạng danh sách") {
                store.send(.setFocusMode(false))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func stepPage(_ step: CookingStepDTO) -> some View {
        VStack(spacing: 0) {
            FocusStepCard(
                step: step,
                index: store.focusIndex,
                total: store.steps.count,
                isDone: store.done.contains(step.stepNo),
                languageMismatch: store.languageMismatch
            ) {
                store.send(.toggleStep(step.stepNo), animation: .snappy)
            }

            ZStack(alignment: .topTrailing) {
                LottieView(animation: .named(CookingAction.resolve(step.actionType).animationName))
                    .playing(loopMode: .loop)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .accessibilityHidden(true)

                if store.showIllustrationNote {
                    SpeechBubble(text: "Meo~ Mình chỉ là hình minh họa cho vui thôi nha, không phải cách nấu của bước này đâu! 🐾")
                        .onTapGesture { store.send(.hideIllustrationNote, animation: .easeOut) }
                        .padding(.top, 8)
                        .padding(.trailing, 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .animation(.easeOut(duration: 0.25), value: store.showIllustrationNote)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let dx = value.translation.width
                guard abs(dx) > 80, abs(dx) > abs(value.translation.height) else { return }
                if dx < 0, !store.isLastStep {
                    goNext()
                } else if dx > 0, !store.isFirstStep {
                    goPrev()
                }
            }
    }

    private func goNext() {
        direction = 1
        store.send(.nextTapped, animation: .spring(response: 0.4, dampingFraction: 0.85))
    }

    private func goPrev() {
        direction = -1
        store.send(.prevTapped, animation: .spring(response: 0.4, dampingFraction: 0.85))
    }

    private var bottomBar: some View {
        HStack {
            Button(action: goPrev) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .frame(width: 72, height: 52)
                    .background(CookingPalette.softButton, in: .rect(cornerRadius: 26))
            }
            .disabled(store.isFirstStep)
            .opacity(store.isFirstStep ? 0.4 : 1)
            .accessibilityLabel("Bước trước")

            Spacer(minLength: 8)
            progressIndicator
            Spacer(minLength: 8)

            Button(action: goNext) {
                Image(systemName: store.isLastStep ? "checkmark" : "arrow.right")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 84, height: 52)
                    .background(store.isLastStep ? CookingPalette.green : CookingPalette.terracotta, in: .rect(cornerRadius: 26))
            }
            .accessibilityLabel(store.isLastStep ? "Hoàn thành món" : "Xong bước này, sang bước sau")
        }
        .buttonStyle(GhibliPressButtonStyle())
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(CookingPalette.cardCream)
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.easeInOut(duration: 0.2), value: store.isLastStep)
    }

    @ViewBuilder
    private var progressIndicator: some View {
        if store.steps.count <= maxDots {
            HStack(spacing: 10) {
                ForEach(Array(store.steps.enumerated()), id: \.element.id) { index, step in
                    let isCurrent = index == store.focusIndex
                    let isDone = store.done.contains(step.stepNo)
                    Circle()
                        .fill(isCurrent ? CookingPalette.terracotta : isDone ? CookingPalette.terracotta.opacity(0.45) : CookingPalette.dotIdle)
                        .frame(width: isCurrent ? 14 : 11, height: isCurrent ? 14 : 11)
                        .contentShape(Rectangle().inset(by: -6))
                        .onTapGesture {
                            direction = index >= store.focusIndex ? 1 : -1
                            store.send(.stepSelected(index), animation: .spring(response: 0.4, dampingFraction: 0.85))
                        }
                }
            }
            .animation(.snappy, value: store.focusIndex)
        } else {
            Text("Bước \(store.focusIndex + 1) / \(store.steps.count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkLabel)
        }
    }
}

// MARK: - Components

private struct FocusStepCard: View {
    let step: CookingStepDTO
    let index: Int
    let total: Int
    let isDone: Bool
    let languageMismatch: Bool
    let onToggle: () -> Void

    private var instructionText: some View {
        Text(step.instruction)
            .font(.system(size: 20))
            .lineSpacing(6)
            .foregroundStyle(Color.Ghibli.inkBody)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Bước \(index + 1)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(CookingPalette.peachPill, in: Capsule())
                Text("\(index + 1) / \(total)")
                    .font(.footnote)
                    .foregroundStyle(Color.Ghibli.inkMuted)
                Spacer()
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(isDone ? CookingPalette.green : .clear)
                        Circle()
                            .strokeBorder(isDone ? CookingPalette.green : Color.Ghibli.straw, lineWidth: 2)
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .accessibilityLabel(isDone ? "Đánh dấu chưa xong" : "Đánh dấu đã xong")
            }

            // Cao theo nội dung, tối đa 220pt rồi cuộn.
            ScrollView { instructionText }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: 220)
                .fixedSize(horizontal: false, vertical: true)

            if languageMismatch {
                Text("Hướng dẫn hiện chỉ có bằng tiếng Việt.")
                    .font(.caption)
                    .foregroundStyle(CookingPalette.warning)
            }
        }
        .padding(20)
        .background(CookingPalette.cardCream.opacity(0.96), in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.Ghibli.straw.opacity(0.45), lineWidth: 1)
        }
        .shadow(color: Color.Ghibli.wood.opacity(0.25), radius: 10, y: 4)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

private struct ListStepCard: View {
    let step: CookingStepDTO
    let isDone: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(isDone ? CookingPalette.green : Color.Ghibli.wood)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                    } else {
                        Text("\(step.stepNo)")
                            .font(.subheadline.weight(.bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bước \(step.stepNo)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkMuted)
                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundStyle(Color.Ghibli.inkDark)
                        .multilineTextAlignment(.leading)
                    Text(isDone ? "Đã xong · chạm để bỏ đánh dấu" : "Chạm để đánh dấu đã xong")
                        .font(.caption2)
                        .foregroundStyle(isDone ? CookingPalette.green : Color.Ghibli.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(isDone ? CookingPalette.doneFill : Color.Ghibli.cream, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isDone ? CookingPalette.green : Color.Ghibli.straw, lineWidth: isDone ? 2 : 1)
            }
        }
        .buttonStyle(GhibliPressButtonStyle())
        .accessibilityAddTraits(isDone ? .isSelected : [])
    }
}

private struct CookingRoundButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.Ghibli.inkDark)
                .frame(width: 48, height: 48)
                .background(CookingPalette.cardCream, in: Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(GhibliPressButtonStyle())
        .accessibilityLabel(label)
    }
}

private struct CookingPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.Ghibli.inkBody)
                .frame(maxWidth: 220, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(CookingPalette.cardCream, in: .rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18).strokeBorder(CookingPalette.peachPill, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
            Triangle()
                .fill(CookingPalette.cardCream)
                .frame(width: 16, height: 9)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview("Cooking steps — focus") {
    CookingStepView(
        store: Store(
            initialState: CookingStepsFeature.State(dishId: "1", title: "Thịt kho tiêu xanh")
        ) {
            CookingStepsFeature()
        } withDependencies: {
            $0.dishDetailClient = .previewValue
        }
    )
}
