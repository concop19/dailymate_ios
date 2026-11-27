//
//  DishDetailInfoView.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import SwiftUI

/// Tab 2 — Thông tin món ăn: thời gian, ẩm thực, độ phù hợp, giá ước tính, vùng miền & mô tả.
struct DishDetailInfoView: View {
    let dish: RankedDishDTO
    let detail: DishDetailDTO?
    let matchPct: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow(
                emoji: "⏱",
                label: "Thời gian nấu",
                value: cookTimeText
            )

            infoRow(
                emoji: "🌏",
                label: "Ẩm thực",
                value: nationDisplayText
            )

            infoRow(
                emoji: "⭐",
                label: "Độ phù hợp",
                value: "\(matchPct)%"
            )

            infoRow(
                emoji: "💰",
                label: "Giá ước tính",
                value: priceText.map { "\($0) / phần" } ?? "—"
            )

            if priceText != nil {
                Text("Giá chỉ mang tính tham khảo theo mặt bằng nguyên liệu phổ thông.")
                    .font(.caption)
                    .foregroundStyle(Color.Ghibli.inkMuted)
                    .padding(.horizontal, 4)
            }

            if let origin = regionText {
                infoRow(
                    emoji: "📍",
                    label: "Vùng miền",
                    value: origin
                )
            }

            if let serving = detail?.servingSize, !serving.isEmpty {
                infoRow(
                    emoji: "🍽️",
                    label: "Định lượng",
                    value: serving.prefix(1).uppercased() + serving.dropFirst()
                )
            }

            if let description = detail?.description?.trimmingCharacters(in: .whitespacesAndNewlines),
               !description.isEmpty {
                PaperCard(cornerRadius: 18, padding: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Giới thiệu món ăn")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.Ghibli.inkDark)
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(Color.Ghibli.inkBody)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 4)
            }
        }
    }

    private func infoRow(emoji: String, label: String, value: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return HStack(spacing: 10) {
            Text(emoji)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkDark)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: 0xFAF6EE), in: shape)
        .overlay {
            shape.strokeBorder(Color.Ghibli.straw.opacity(0.75), lineWidth: 1)
        }
    }

    private var cookTimeText: String {
        if let mins = dish.cookTimeMin ?? detail?.cookTimeMinutes, mins > 0 {
            return "\(mins) phút"
        }
        return "—"
    }

    private var nationDisplayText: String {
        guard let raw = (dish.nation ?? detail?.nation)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return "Việt Nam"
        }
        switch raw.lowercased() {
        case "vietnam", "vn": return "Việt Nam"
        case "japan", "jp":   return "Nhật Bản"
        case "korea", "kr":   return "Hàn Quốc"
        case "china", "cn":   return "Trung Hoa"
        case "thailand", "th": return "Thái Lan"
        default:              return raw.capitalized
        }
    }

    private var priceText: String? {
        guard let amount = dish.estCostVnd ?? detail?.estCostVnd, amount > 0 else { return nil }
        let rounded = Int((amount / 1000).rounded()) * 1000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
        return "\(formatted)đ"
    }

    private var regionText: String? {
        if let specialty = detail?.specialtyOrigin?.trimmingCharacters(in: .whitespacesAndNewlines),
           !specialty.isEmpty {
            return specialty
        }
        switch detail?.cuisineRegion?.lowercased() {
        case "northern":     return "Miền Bắc"
        case "central":      return "Miền Trung"
        case "southern":     return "Miền Nam"
        case "northwestern": return "Tây Bắc"
        case "highland":     return "Tây Nguyên"
        case "national":     return "Toàn quốc"
        default:             return nil
        }
    }
}
