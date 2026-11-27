//
//  WhyPresenter.swift
//  dailymate
//

import SwiftUI

/// Chuyển `WhyDTO` từ server thành câu chữ tiếng Việt để hiển thị (port gọn từ WhyText.kt).
/// Chỉ có logic, không có view — dễ viết unit test.
enum WhyPresenter {
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
