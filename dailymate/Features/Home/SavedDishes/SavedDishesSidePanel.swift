//
//  SavedDishesSidePanel.swift
//  dailymate
//

import ComposableArchitecture
import SwiftUI

/// Ngăn kéo "Món đã lưu" nằm ở mép phải màn hình Home.
/// Khi đóng chỉ thấy một tab nhỏ; kéo tab từ phải sang trái (hoặc chạm) để mở.
struct SavedDishesSidePanel: View {
    let store: StoreOf<SavedDishesFeature>

    @State private var isOpen = false
    @GestureState private var dragX: CGFloat = 0

    private let handleWidth: CGFloat = 30
    private let handleHeight: CGFloat = 96

    var body: some View {
        GeometryReader { geo in
            let panelWidth = min(geo.size.width * 0.82, 340)
            let panelHeight = min(geo.size.height * 0.72, 560)
            let baseOffset = isOpen ? 0 : panelWidth
            let offset = min(max(baseOffset + dragX, 0), panelWidth)
            let progress = 1 - offset / panelWidth

            ZStack(alignment: .trailing) {
                // Lớp mờ phía sau khi mở; chạm để đóng.
                Color.black
                    .opacity(0.25 * progress)
                    .ignoresSafeArea()
                    .allowsHitTesting(isOpen)
                    .onTapGesture { setOpen(false) }

                HStack(alignment: .center, spacing: 0) {
                    handle
                    SavedDishesView(store: store)
                        .frame(width: panelWidth, height: panelHeight)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 24))
                        .shadow(color: Color.Ghibli.wood.opacity(0.18), radius: 12, x: -4)
                }
                .offset(x: offset)
                .gesture(dragGesture(panelWidth: panelWidth))
                .frame(maxHeight: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .trailing)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isOpen)
    }

    private var handle: some View {
        Button {
            setOpen(!isOpen)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isOpen ? "chevron.right" : "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.Ghibli.straw)
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF59E0B))
                if !store.dishes.isEmpty {
                    Text("\(store.dishes.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.Ghibli.wood)
                }
            }
            .frame(width: handleWidth, height: handleHeight)
            .background(
                Color(hex: 0xFAF5EA),
                in: UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14)
            )
            .overlay {
                UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14)
                    .strokeBorder(Color.Ghibli.straw.opacity(0.6), lineWidth: 1)
            }
            .shadow(color: Color.Ghibli.wood.opacity(0.15), radius: 6, x: -2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOpen ? "Đóng món đã lưu" : "Mở món đã lưu")
    }

    private func dragGesture(panelWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($dragX) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let predicted = value.predictedEndTranslation.width
                if isOpen {
                    setOpen(!(predicted > panelWidth * 0.35))
                } else {
                    setOpen(predicted < -panelWidth * 0.35)
                }
            }
    }

    private func setOpen(_ open: Bool) {
        if open { store.send(.reload) }
        isOpen = open
    }
}
