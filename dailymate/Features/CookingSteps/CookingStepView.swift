//
//  CookingStepView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import SwiftUI

/// Màn các bước nấu: chuyển giữa chế độ danh sách (`CookingListScreen`) và từng bước (`CookingFocusView`),
/// kèm popup chúc mừng khi hoàn thành. Các thành phần con nằm trong `List/`, `Focus/`, `Components/`.
struct CookingStepView: View {
    @Bindable var store: StoreOf<CookingStepsFeature>

    var body: some View {
        ZStack {
            if store.showsFocusScreen {
                CookingFocusView(store: store)
                    .transition(.opacity)
            } else {
                CookingListScreen(store: store)
                    .transition(.opacity)
            }

            if store.showFinishPopup {
                CookingFinishPopup(
                    dishTitle: store.title,
                    onConfirm: { store.send(.finishConfirmed) },
                    onDismiss: { store.send(.finishPopupDismissed) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.showsFocusScreen)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.showFinishPopup)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { store.send(.onAppear) }
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
