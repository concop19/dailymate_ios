//
//  HomeModeCardsView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import SwiftUI

/// Hai nhãn chế độ gợi ý — chỉ để hiển thị, không bấm chọn.
/// Hiện chỉ có "Gợi ý tùy chọn" hoạt động; "Từ tủ lạnh" chưa làm nên gắn nhãn "Sắp có".
struct HomeModeCardsView: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(HomeFeature.SuggestionMode.allCases) { mode in
                MascotBanner(
                    message: mode.title,
                    animationName: mode.emoji,
                    direction: .vertical,
                    mascotSize: 60,
                    bubleBackground: .clear,
                    showBorder: false
                )
                .frame(maxWidth: .infinity, minHeight: 112)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .overlay(alignment: .topTrailing) {
                    if mode == .fromFridge {
                        Text("Sắp có")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.Ghibli.wood)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.Ghibli.cream.opacity(0.95), in: Capsule())
                            .overlay { Capsule().strokeBorder(Color.Ghibli.straw.opacity(0.6), lineWidth: 1) }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview {
    HomeModeCardsView()
        .padding()
        .background(Color.Ghibli.cream)
}
