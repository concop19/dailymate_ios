//
//  DishDetailRecommendedView.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import SwiftUI

/// Tab 1 — Vì sao hợp: hiển thị phân tích `WhyDTO` (headline, xếp hạng, công thức/tỷ trọng, lý do, điểm trừ, độ phù hợp).
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
            PaperCard(cornerRadius: 20, padding: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("✨ \(legacy.headline)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkDark)

                    if let tags = legacy.tags, !tags.isEmpty {
                        OnboardingFlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
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
        } else {
            Text("Chưa có phân tích lý do gợi ý cho món này.")
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        }
    }

    // MARK: - Main Why Card

    private func whyCard(_ why: WhyDTO) -> some View {
        let reasons = why.reasons.map(WhyPresenter.reason)
        let tradeoffs = (why.tradeoffs ?? []).map(WhyPresenter.tradeoff).filter { !$0.text.isEmpty }
        let formula = why.formula.map(WhyPresenter.formula)
        let fitGroups = WhyGroup.allCases.filter { why.fit?[$0.rawValue] != nil }

        return PaperCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                // Headline kết luận
                HStack(alignment: .top, spacing: 8) {
                    Text("✨")
                    Text(WhyPresenter.headline(why))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkDark)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Badge xếp hạng
                if let rank = why.rank, let pos = rank.pos {
                    HStack(spacing: 8) {
                        let pctText = rank.matchPct.map { " · \(Int($0.rounded()))%" } ?? ""
                        Text("Hạng #\(pos)\(pctText)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0x8A5D00))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xFFF1DC), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if rank.liftedForVariety == true {
                            Text("🔀 Đẩy lên để đổi vị")
                                .font(.caption)
                                .foregroundStyle(Color.Ghibli.inkMuted)
                        }
                    }
                }

                // Công thức điểm hoặc thanh tỷ trọng
                if let formula {
                    formulaBlock(formula)
                } else if let share = why.share, !share.isEmpty {
                    shareBar(share)
                }

                // Danh sách lý do
                if !reasons.isEmpty {
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

                // Điểm cần cân nhắc (Tradeoffs)
                if !tradeoffs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Điểm cần cân nhắc")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color(hex: 0x8A5D00))

                        ForEach(tradeoffs) { item in
                            HStack(alignment: .top, spacing: 6) {
                                Text(item.emoji)
                                Text(item.text)
                                    .font(.footnote)
                                    .foregroundStyle(Color(hex: 0x8A5D00))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: 0xFFF4E5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // Độ phù hợp theo từng nhóm
                if !fitGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Độ phù hợp từng yếu tố")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color.Ghibli.inkLabel)

                        ForEach(fitGroups) { group in
                            fitBar(group: group, value: why.fit?[group.rawValue] ?? 0)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Subviews

    private func formulaBlock(_ view: WhyFormulaView) -> some View {
        let maxAbs = max(view.rows.map { abs($0.edge) }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Phân tích điểm số")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkLabel)

            Text(
                view.base.map { "Điểm \(view.score) (trung bình \($0))" }
                    ?? "Điểm tổng \(view.score)"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.Ghibli.inkDark)

            ForEach(view.rows) { row in
                HStack(spacing: 8) {
                    Text(row.emoji)
                        .frame(width: 22)

                    Text(row.label + (row.mult.map { " \($0)" } ?? ""))
                        .font(.caption)
                        .foregroundStyle(Color.Ghibli.inkBody)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GeometryReader { geo in
                        let ratio = CGFloat(abs(row.edge)) / CGFloat(maxAbs) * (animateBars ? 1 : 0)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(hex: 0xE7DEC8))
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(row.edge >= 0 ? row.color : Color(hex: 0xB5543C))
                                .frame(width: max(0, geo.size.width * ratio))
                        }
                    }
                    .frame(width: 84, height: 8)

                    Text(WhyPresenter.signed(row.edge))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(row.edge >= 0 ? Color(hex: 0x4E9A68) : Color(hex: 0xB5543C))
                        .frame(width: 34, alignment: .trailing)
                }
            }

            if view.base != nil {
                Text("Mỗi dòng cho biết món này hơn hoặc kém mức trung bình bao nhiêu điểm.")
                    .font(.caption2)
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }
        }
    }

    private func shareBar(_ share: [String: Double]) -> some View {
        let groups = WhyGroup.allCases.filter { (share[$0.rawValue] ?? 0) > 0 }
        let total = max(groups.reduce(0.0) { $0 + (share[$1.rawValue] ?? 0) }, 0.001)
        return Group {
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
                                    .frame(width: geo.size.width * weight * (animateBars ? 1 : 0))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: 0xE7DEC8))
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

    private func fitBar(group: WhyGroup, value: Double) -> some View {
        let pct = min(max(Int((value * 100).rounded()), 0), 100)
        return HStack(spacing: 8) {
            Text(group.emoji)
                .frame(width: 22)

            Text(group.label)
                .font(.caption)
                .foregroundStyle(Color.Ghibli.inkBody)
                .lineLimit(1)
                .frame(width: 112, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(hex: 0xE7DEC8))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(group.color)
                        .frame(width: geo.size.width * (CGFloat(pct) / 100.0) * (animateBars ? 1 : 0))
                }
            }
            .frame(height: 8)

            Text("\(pct)%")
                .font(.caption.weight(.bold))
                .foregroundStyle(group.color)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

// MARK: - Why Presenter (Port gọn từ WhyText.kt)

private enum WhyGroup: String, CaseIterable, Identifiable {
    case weather = "weather"
    case taste = "taste"
    case placeSeason = "place_season"
    case basket = "basket"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weather:     "Thời tiết & cơ thể"
        case .taste:       "Khẩu vị"
        case .placeSeason: "Vùng miền & mùa"
        case .basket:      "Giỏ nguyên liệu"
        }
    }

    var emoji: String {
        switch self {
        case .weather:     "⛅"
        case .taste:       "🍽️"
        case .placeSeason: "🍃"
        case .basket:      "🧺"
        }
    }

    var color: Color {
        switch self {
        case .weather:     Color(hex: 0xD9822B)
        case .taste:       Color(hex: 0xC0573E)
        case .placeSeason: Color(hex: 0x4E9A68)
        case .basket:      Color(hex: 0x7C6BB0)
        }
    }
}

private struct WhyReasonView: Identifiable {
    let id = UUID()
    let emoji: String
    let color: Color
    let title: String
    let chips: [String]
}

private struct WhyTradeoffView: Identifiable {
    let id = UUID()
    let emoji: String
    let text: String
}

private struct WhyFormulaRow: Identifiable {
    let id: String
    let emoji: String
    let color: Color
    let label: String
    let mult: String?
    var edge: Int
}

private struct WhyFormulaView {
    let score: Int
    let base: Int?
    let rows: [WhyFormulaRow]
}

private enum WhyPresenter {
    static func signed(_ n: Int) -> String {
        if n > 0 { return "+\(n)" }
        if n < 0 { return "−\(-n)" }
        return "±0"
    }

    static func headline(_ why: WhyDTO) -> String {
        let parts = why.reasons.map(shortPhrase).filter { !$0.isEmpty }.prefix(2)
        guard !parts.isEmpty else { return "Hợp với bữa hôm nay" }
        let joined = parts.joined(separator: ", ")
        return joined.prefix(1).uppercased() + joined.dropFirst()
    }

    static func shortPhrase(_ item: WhyItemDTO) -> String {
        let f = item.facts
        switch item.code {
        case "weather_cooling":
            return f?.temp.map { "món mát cho trời \(Int($0.rounded()))°C" } ?? "món thanh mát hợp thời tiết"
        case "weather_warming":
            return f?.temp.map { "món ấm cho trời \(Int($0.rounded()))°C" } ?? "món ấm bụng hợp thời tiết"
        case "weather_hydration":
            return "bổ sung nước tốt"
        case "body_satiety":
            return "no lâu, đủ chất"
        case "body_energy":
            return "năng lượng phù hợp"
        case "basket_ready":
            return "nấu được ngay từ đồ bạn có"
        case "basket_partial":
            if let have = f?.mainHave, let total = f?.mainTotal {
                return "đã có \(have)/\(total) nguyên liệu chính"
            }
            return "khớp nguyên liệu đang có"
        case "liked":
            return "hợp nhóm món bạn thích"
        case "taste_match":
            let names = (f?.tastes ?? []).map { tasteLabel($0.k) }.filter { !$0.isEmpty }
            if !names.isEmpty { return "đúng gu \(names.joined(separator: " & "))" }
            if let avoid = f?.avoids?.first { return "tránh vị \(tasteLabel(avoid))" }
            return ""
        case "local_season":
            let ings = (f?.ings ?? []).filter { !$0.isEmpty }
            return ings.isEmpty ? "" : "đúng mùa \(ings.joined(separator: ", "))"
        case "home_region":
            return "đậm vị \(regionLabel(f?.region))"
        default:
            return ""
        }
    }

    static func reason(_ item: WhyItemDTO) -> WhyReasonView {
        let f = item.facts
        let (group, emoji) = reasonStyle(item.code)
        var chips: [String] = []
        let ings = (f?.ings ?? []).filter { !$0.isEmpty }

        let title: String
        switch item.code {
        case "weather_cooling":
            if !ings.isEmpty { chips.append("Nhờ \(ings.joined(separator: ", "))") }
            if let temp = f?.temp, let pct = f?.pct {
                title = "Trời \(Int(temp.rounded()))°C — món mát hơn \(Int(pct.rounded()))% món trong kho"
            } else {
                title = "Món thanh mát, dễ ăn trong thời tiết hiện tại"
            }
        case "weather_warming":
            if !ings.isEmpty { chips.append("Nhờ \(ings.joined(separator: ", "))") }
            if let temp = f?.temp, let pct = f?.pct {
                title = "Trời \(Int(temp.rounded()))°C — món làm ấm hơn \(Int(pct.rounded()))% món trong kho"
            } else {
                title = "Món nóng ấm, hợp thời tiết mát lạnh"
            }
        case "weather_hydration":
            if !ings.isEmpty { chips.append("Nhờ \(ings.joined(separator: ", "))") }
            title = "Giàu nước, giúp bù nước hiệu quả"
        case "body_satiety":
            if !ings.isEmpty { chips.append("Nhờ \(ings.joined(separator: ", "))") }
            title = f?.pct.map { "Độ no cao hơn \(Int($0.rounded()))% món khác" } ?? "Giúp no lâu và cân bằng bữa ăn"
        case "body_energy":
            if let kcal = f?.kcal, let target = f?.target {
                title = "Khoảng \(Int(kcal.rounded())) kcal, gần mức mục tiêu \(Int(target.rounded())) kcal"
            } else {
                title = "Mức năng lượng phù hợp thể trạng"
            }
        case "taste_match":
            for t in f?.tastes ?? [] {
                let name = tasteLabel(t.k)
                if let user = t.user { chips.append("Gu \(name): \(Int(user.rounded()))/10") }
                if let pct = t.pct { chips.append("Món \(name) \(Int(pct.rounded()))%") }
            }
            for avoid in f?.avoids ?? [] {
                chips.append("Tránh \(tasteLabel(avoid))")
            }
            title = f?.source == "profile" ? "Khớp sát hồ sơ khẩu vị của bạn" : "Hợp khẩu vị đặc trưng vùng miền"
        case "local_season":
            if !ings.isEmpty { chips.append("Đang mùa: \(ings.joined(separator: ", "))") }
            if let avail = f?.avail, avail < 95 { chips.append("Dễ tìm \(Int(avail.rounded()))%") }
            title = f?.province.map { "Nguyên liệu đang đúng mùa, dễ mua tại \($0)" }
                ?? "Nguyên liệu đang đúng mùa, dễ tìm mua"
        case "home_region":
            if let origin = f?.origin, !origin.isEmpty { chips.append("Nguồn gốc: \(origin)") }
            if let everyday = f?.everyday { chips.append(everyday ? "Món cơm nhà quen thuộc" : "Đặc sản vùng miền") }
            title = "Hợp phong vị ẩm thực \(regionLabel(f?.region))"
        case "basket_ready", "basket_partial":
            let have = (f?.have ?? []).filter { !$0.isEmpty }
            let missing = (f?.missing ?? []).filter { !$0.isEmpty }
            if !have.isEmpty { chips.append("Đã có: \(have.joined(separator: ", "))") }
            if !missing.isEmpty { chips.append("Thiếu: \(missing.joined(separator: ", "))") }
            if item.code == "basket_ready" {
                title = "Đủ nguyên liệu chính từ giỏ bạn đã chọn"
            } else if let mh = f?.mainHave, let mt = f?.mainTotal {
                title = "Đã có \(mh)/\(mt) nguyên liệu chính trong giỏ"
            } else {
                title = "Dùng được một phần nguyên liệu bạn đang có"
            }
        case "liked":
            title = "Tương đồng với các món bạn từng yêu thích"
        default:
            title = shortPhrase(item)
        }

        return WhyReasonView(emoji: emoji, color: group.color, title: title, chips: chips)
    }

    static func tradeoff(_ item: WhyItemDTO) -> WhyTradeoffView {
        let f = item.facts
        var text: String
        switch item.code {
        case "cook_time_over":
            if let min = f?.min, let limit = f?.limit {
                text = "Nấu khoảng \(Int(min.rounded())) phút, lâu hơn mức \(Int(limit.rounded())) phút"
            } else {
                text = "Thời gian nấu hơi lâu hơn mức mong muốn"
            }
        case "price_above":
            text = f?.vnd.map { "Khoảng \(formatShortVND($0))/phần, cao hơn mức bạn muốn" }
                ?? "Chi phí ước tính cao hơn mức mong muốn"
        case "off_season":
            text = "Chưa vào chính mùa \(seasonLabel(f?.season))"
        case "other_region":
            text = "Thuộc phong vị \(regionLabel(f?.region))"
        case "taste_off":
            text = f?.k.map { "Vị \(tasteLabel($0)) hơi lệch so với khẩu vị" } ?? "Khẩu vị hơi khác nhẹ"
        case "need_buy":
            let missing = (f?.missing ?? []).filter { !$0.isEmpty }
            text = missing.isEmpty ? "Cần mua thêm vài nguyên liệu" : "Cần mua thêm: \(missing.joined(separator: ", "))"
        case "weather_below":
            text = "Độ hợp thời tiết ở mức trung bình"
        case "eaten_recently":
            text = "Bạn vừa xem hoặc ăn món này gần đây"
        case "disliked":
            text = "Gần với nhóm món bạn từng bỏ qua"
        default:
            text = ""
        }

        if !text.isEmpty, let loss = item.loss, loss > 0 {
            text += " (−\(Int(loss.rounded())) điểm)"
        }
        return WhyTradeoffView(emoji: tradeoffEmoji(item.code), text: text)
    }

    static func formula(_ f: WhyFormulaDTO) -> WhyFormulaView {
        var rows: [WhyFormulaRow] = (f.terms ?? []).map { term in
            let group = WhyGroup(rawValue: term.k)
            return WhyFormulaRow(
                id: term.k,
                emoji: group?.emoji ?? "•",
                color: group?.color ?? Color.Ghibli.inkMuted,
                label: group?.label ?? term.k,
                mult: nil,
                edge: Int((term.edge * 100).rounded())
            )
        }

        for m in f.mults ?? [] {
            let up = m.x > 1
            rows.append(
                WhyFormulaRow(
                    id: "m_\(m.k)",
                    emoji: multEmoji(m.k),
                    color: up ? Color(hex: 0x4E9A68) : Color(hex: 0xB5543C),
                    label: multLabel(m.k, up: up),
                    mult: String(format: "×%.2f", m.x),
                    edge: Int((m.edge * 100).rounded())
                )
            )
        }

        let score = Int((f.score * 100).rounded())
        let base = f.base.map { Int(($0 * 100).rounded()) }
        if let base, !rows.isEmpty {
            let diff = score - base
            let drift = diff - rows.reduce(0) { $0 + $1.edge }
            if drift != 0, let topIdx = rows.indices.max(by: { abs(rows[$0].edge) < abs(rows[$1].edge) }) {
                rows[topIdx].edge += drift
            }
        }
        return WhyFormulaView(score: score, base: base, rows: rows)
    }

    private static func reasonStyle(_ code: String) -> (WhyGroup, String) {
        switch code {
        case "weather_cooling":   return (.weather, "❄️")
        case "weather_warming":   return (.weather, "🔥")
        case "weather_hydration": return (.weather, "💧")
        case "body_satiety":      return (.weather, "🧍")
        case "body_energy":       return (.weather, "⚡")
        case "taste_match":       return (.taste, "🍽️")
        case "local_season":      return (.placeSeason, "🍃")
        case "home_region":       return (.placeSeason, "🏡")
        case "basket_ready":      return (.basket, "✅")
        case "basket_partial":    return (.basket, "🧺")
        case "liked":             return (.taste, "❤️")
        default:                  return (.taste, "✨")
        }
    }

    private static func tradeoffEmoji(_ code: String) -> String {
        switch code {
        case "cook_time_over": return "⏱"
        case "price_above":    return "💰"
        case "off_season":     return "📅"
        case "eaten_recently": return "🔁"
        case "disliked":       return "👎"
        case "weather_below":  return "🌡️"
        case "other_region":   return "🗺️"
        case "need_buy":       return "🛒"
        default:               return "⚠️"
        }
    }

    private static func multEmoji(_ key: String) -> String {
        switch key {
        case "soft":   return "⏱"
        case "liked":  return "❤️"
        case "region": return "🏡"
        case "recent": return "🔁"
        default:       return "✕"
        }
    }

    private static func multLabel(_ key: String, up: Bool) -> String {
        switch (key, up) {
        case ("soft", _):       return "Thời gian & chi phí"
        case ("liked", true):   return "Hợp món từng thích"
        case ("liked", false):  return "Giống món từng bỏ qua"
        case ("region", true):  return "Đúng vùng miền"
        case ("region", false): return "Khác vùng miền"
        case ("recent", _):     return "Vừa ăn gần đây"
        default:                return key
        }
    }

    private static func tasteLabel(_ key: String) -> String {
        switch key.lowercased() {
        case "sweet":      return "ngọt"
        case "sour":       return "chua"
        case "salty":      return "mặn"
        case "bitter":     return "đắng"
        case "umami":      return "đậm đà"
        case "spicy":      return "cay"
        case "astringent": return "chát"
        default:           return key
        }
    }

    private static func regionLabel(_ key: String?) -> String {
        switch key?.lowercased() {
        case "northern":     return "miền Bắc"
        case "central":      return "miền Trung"
        case "southern":     return "miền Nam"
        case "northwestern": return "Tây Bắc"
        case "highland":     return "Tây Nguyên"
        case "national":     return "toàn quốc"
        default:             return key ?? "Việt Nam"
        }
    }

    private static func seasonLabel(_ key: String?) -> String {
        switch key?.lowercased() {
        case "spring": return "mùa xuân"
        case "summer": return "mùa hạ"
        case "autumn": return "mùa thu"
        case "winter": return "mùa đông"
        default:       return key ?? ""
        }
    }

    private static func formatShortVND(_ vnd: Double) -> String {
        let k = Int((vnd / 1000).rounded())
        return "\(max(k, 1))k"
    }
}
