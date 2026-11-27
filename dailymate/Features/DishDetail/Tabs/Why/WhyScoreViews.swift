//
//  WhyScoreViews.swift
//  dailymate
//

import SwiftUI

/// "Phân tích điểm số": mỗi dòng là một yếu tố cộng / trừ điểm so với trung bình.
struct WhyFormulaBlock: View {
    let formula: WhyFormulaView
    var isAnimated: Bool = true

    private static let positive = Color(hex: 0x4E9A68)
    private static let negative = Color(hex: 0xB5543C)

    var body: some View {
        let maxAbs = max(formula.rows.map { abs($0.edge) }.max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 8) {
            Text("Phân tích điểm số")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkLabel)

            Text(
                formula.base.map { "Điểm \(formula.score) (trung bình \($0))" }
                    ?? "Điểm tổng \(formula.score)"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.Ghibli.inkDark)

            ForEach(formula.rows) { row in
                HStack(spacing: 8) {
                    Text(row.emoji)
                        .frame(width: 22)

                    Text(row.label + (row.mult.map { " \($0)" } ?? ""))
                        .font(.caption)
                        .foregroundStyle(Color.Ghibli.inkBody)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    WhyBar(
                        ratio: CGFloat(abs(row.edge)) / CGFloat(maxAbs),
                        color: row.edge >= 0 ? row.color : Self.negative,
                        isAnimated: isAnimated
                    )
                    .frame(width: 84)

                    Text(WhyPresenter.signed(row.edge))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(row.edge >= 0 ? Self.positive : Self.negative)
                        .frame(width: 34, alignment: .trailing)
                }
            }

            if formula.base != nil {
                Text("Mỗi dòng cho biết món này hơn hoặc kém mức trung bình bao nhiêu điểm.")
                    .font(.caption2)
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }
        }
    }
}

/// "Tỷ trọng đóng góp": một thanh chia màu theo nhóm + chú thích %. Dùng khi server không gửi `formula`.
struct WhyShareBar: View {
    let share: [String: Double]
    var isAnimated: Bool = true

    private var groups: [WhyGroup] {
        WhyGroup.allCases.filter { (share[$0.rawValue] ?? 0) > 0 }
    }

    var body: some View {
        let groups = self.groups
        let total = max(groups.reduce(0.0) { $0 + (share[$1.rawValue] ?? 0) }, 0.001)

        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tỷ trọng đóng góp")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkLabel)

                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(groups) { group in
                            let weight = (share[group.rawValue] ?? 0) / total
                            Rectangle()
                                .fill(group.color)
                                .frame(width: geo.size.width * weight * (isAnimated ? 1 : 0))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(WhyBar.trackColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .frame(height: 12)

                OnboardingFlowLayout(horizontalSpacing: 12, verticalSpacing: 4) {
                    ForEach(groups) { group in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(group.color)
                                .frame(width: 8, height: 8)
                            Text("\(group.label) \(Int(((share[group.rawValue] ?? 0) * 100).rounded()))%")
                                .font(.caption)
                                .foregroundStyle(Color.Ghibli.inkBody)
                        }
                    }
                }
            }
        }
    }
}

/// "Độ phù hợp từng yếu tố": mỗi nhóm một thanh %.
struct WhyFitSection: View {
    let fit: [String: Double]
    var isAnimated: Bool = true

    var body: some View {
        let groups = WhyGroup.allCases.filter { fit[$0.rawValue] != nil }

        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Độ phù hợp từng yếu tố")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkLabel)

                ForEach(groups) { group in
                    row(group: group, value: fit[group.rawValue] ?? 0)
                }
            }
        }
    }

    private func row(group: WhyGroup, value: Double) -> some View {
        let pct = min(max(Int((value * 100).rounded()), 0), 100)
        return HStack(spacing: 8) {
            Text(group.emoji)
                .frame(width: 22)

            Text(group.label)
                .font(.caption)
                .foregroundStyle(Color.Ghibli.inkBody)
                .lineLimit(1)
                .frame(width: 112, alignment: .leading)

            WhyBar(ratio: CGFloat(pct) / 100, color: group.color, isAnimated: isAnimated)

            Text("\(pct)%")
                .font(.caption.weight(.bold))
                .foregroundStyle(group.color)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
