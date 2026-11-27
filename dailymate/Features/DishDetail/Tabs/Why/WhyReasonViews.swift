//
//  WhyReasonViews.swift
//  dailymate
//

import SwiftUI

/// Danh sách lý do gợi ý (emoji tròn + câu + các chip chi tiết).
struct WhyReasonList: View {
    let reasons: [WhyReasonView]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(reasons) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text(item.emoji)
                        .font(.subheadline)
                        .frame(width: 30, height: 30)
                        .background(item.color.opacity(0.14), in: Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.Ghibli.inkDark)

                        if !item.chips.isEmpty {
                            OnboardingFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                                ForEach(item.chips, id: \.self) { chip in
                                    Text(chip)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(item.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            item.color.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

/// Hộp vàng "Điểm cần cân nhắc".
struct WhyTradeoffBox: View {
    let tradeoffs: [WhyTradeoffView]

    private static let ink = Color(hex: 0x8A5D00)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Điểm cần cân nhắc")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Self.ink)

            ForEach(tradeoffs) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text(item.emoji)
                    Text(item.text)
                        .font(.footnote)
                        .foregroundStyle(Self.ink)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: 0xFFF4E5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
