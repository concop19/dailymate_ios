//
//  DishDetailRecommendedView.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import SwiftUI

/// Tab "Vì sao hợp": hiển thị phân tích `WhyDTO` (headline, xếp hạng, công thức/tỷ trọng, lý do, điểm trừ, độ phù hợp).
/// Chữ hiển thị do `WhyPresenter` tạo; các khối con nằm trong `Tabs/Why/`.
struct DishDetailRecommendedView: View {
    let why: WhyDTO?
    let legacyExplanation: DishLegacyExplanationDTO?

    @State private var animateBars = false

    var body: some View {
        if let why {
            whyCard(why)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.65)) {
                        animateBars = true
                    }
                }
        } else if let legacy = legacyExplanation, !legacy.headline.isEmpty {
            WhyLegacyCard(explanation: legacy)
        } else {
            Text("Chưa có phân tích lý do gợi ý cho món này.")
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        }
    }

    private func whyCard(_ why: WhyDTO) -> some View {
        let reasons = why.reasons.map(WhyPresenter.reason)
        let tradeoffs = (why.tradeoffs ?? []).map(WhyPresenter.tradeoff).filter { !$0.text.isEmpty }

        return PaperCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                WhyHeadline(text: WhyPresenter.headline(why))

                if let rank = why.rank, let position = rank.pos {
                    WhyRankBadge(
                        position: position,
                        matchPct: rank.matchPct,
                        liftedForVariety: rank.liftedForVariety == true
                    )
                }

                // Có công thức điểm thì hiện phân tích chi tiết, không thì hiện thanh tỷ trọng.
                if let formula = why.formula.map(WhyPresenter.formula) {
                    WhyFormulaBlock(formula: formula, isAnimated: animateBars)
                } else if let share = why.share, !share.isEmpty {
                    WhyShareBar(share: share, isAnimated: animateBars)
                }

                if !reasons.isEmpty {
                    WhyReasonList(reasons: reasons)
                }

                if !tradeoffs.isEmpty {
                    WhyTradeoffBox(tradeoffs: tradeoffs)
                }

                if let fit = why.fit {
                    WhyFitSection(fit: fit, isAnimated: animateBars)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
