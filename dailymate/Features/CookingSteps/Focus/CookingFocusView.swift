//
//  CookingFocusView.swift
//  dailymate
//

import ComposableArchitecture
import Lottie
import SwiftUI

/// Chế độ "Từng bước": nền bếp, thẻ bước hiện tại, Lottie mèo theo loại thao tác, vuốt / bấm để chuyển bước.
struct CookingFocusView: View {
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
            CookingStepDots(
                steps: store.steps,
                currentIndex: store.focusIndex,
                doneStepNos: store.done
            ) { index in
                direction = index >= store.focusIndex ? 1 : -1
                store.send(.stepSelected(index), animation: .spring(response: 0.4, dampingFraction: 0.85))
            }
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
}
