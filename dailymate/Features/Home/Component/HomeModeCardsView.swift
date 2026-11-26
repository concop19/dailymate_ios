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
                    .background(
                        isSelected ? Color(hex: 0xFFFBF2) : Color(hex: 0xF7F2E7).opacity(0.95),
                        in: cardShape
                    )
                    .overlay {
                        cardShape.strokeBorder(
                            isSelected ? Color.Ghibli.sky : Color.Ghibli.straw.opacity(0.75),
                            lineWidth: isSelected ? 2.2 : 1.5
                        )
                    }
                    .shadow(
                        color: (isSelected ? Color.Ghibli.sky : Color.Ghibli.wood).opacity(isSelected ? 0.18 : 0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
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
