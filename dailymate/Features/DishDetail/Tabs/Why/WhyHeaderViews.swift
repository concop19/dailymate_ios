//
//  WhyHeaderViews.swift
//  dailymate
//

import SwiftUI

/// Câu kết luận "✨ …" ở đầu thẻ.
struct WhyHeadline: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("✨")
            Text(text)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkDark)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Badge "Hạng #n · x%" (+ ghi chú nếu món được đẩy lên để đổi vị).
struct WhyRankBadge: View {
    let position: Int
    let matchPct: Double?
    let liftedForVariety: Bool

    var body: some View {
        HStack(spacing: 8) {
            let pctText = matchPct.map { " · \(Int($0.rounded()))%" } ?? ""
            Text("Hạng #\(position)\(pctText)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: 0x8A5D00))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: 0xFFF1DC), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if liftedForVariety {
                Text("🔀 Đẩy lên để đổi vị")
                    .font(.caption)
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }
        }
    }
}

/// Thẻ dự phòng cho dữ liệu cũ (`explanation`): headline + các tag.
struct WhyLegacyCard: View {
    let explanation: DishLegacyExplanationDTO

    var body: some View {
        PaperCard(cornerRadius: 20, padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("✨ \(explanation.headline)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkDark)

                if let tags = explanation.tags, !tags.isEmpty {
                    FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.Ghibli.inkBody)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: 0xFAF5EA), in: Capsule())
                                .overlay { Capsule().strokeBorder(Color.Ghibli.straw.opacity(0.6), lineWidth: 1) }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
