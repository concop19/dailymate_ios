//
//  HomeModeCardsView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import SwiftUI

struct HomeModeCardsView: View {
    let selectedMode: HomeFeature.SuggestionMode
    let onSelect: (HomeFeature.SuggestionMode) -> Void

    private let cardShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        HStack(spacing: 12) {
            ForEach(HomeFeature.SuggestionMode.allCases) { mode in
                let isSelected = mode == selectedMode

                Button {
                    onSelect(mode)
                } label: {
                    VStack(spacing: 10) {
                        MascotBanner(message: mode.title, animationName: mode.emoji, direction: .vertical,  mascotSize: 60,
                                     bubleBackground: .clear,
                                     showBorder: false)

                       
                    }
                    .frame(maxWidth: .infinity, minHeight: 112)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    // Không đổ nền: thẻ được chọn chỉ ánh nhẹ (lớp sáng mờ + viền xanh phát sáng).
                    .background {
                        cardShape.fill(
                            LinearGradient(
                                colors: [Color.white.opacity(isSelected ? 0.22 : 0), Color.white.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .overlay {
                        cardShape.strokeBorder(
                            isSelected ? Color.Ghibli.sky : Color.clear,
                            lineWidth: isSelected ? 2 : 1.5
                        )
                    }
                    .shadow(color: Color.Ghibli.sky.opacity(isSelected ? 0.45 : 0), radius: isSelected ? 10 : 0)
                    .animation(.easeInOut(duration: 0.25), value: isSelected)
                }
                .buttonStyle(.ghibliPress)
            }
        }
    }
}

#Preview {
    HomeModeCardsView(selectedMode: .recommended) { _ in }
        .padding()
        .background(Color.Ghibli.cream)
}
