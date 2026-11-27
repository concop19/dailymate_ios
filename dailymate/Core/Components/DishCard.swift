//
//  DishCard.swift
//  dailymate
//

import Kingfisher
import SwiftUI

/// Thẻ món ăn dùng chung (danh sách gợi ý, món đã lưu...).
/// Chỉ là phần hiển thị — nơi dùng tự bọc trong `Button` / `NavigationLink` / row của `List`.
struct DishCard: View {
    let title: String
    let imageURL: URL?
    var rank: Int? = nil
    var matchPct: Double? = nil
    var cookTimeMin: Int? = nil
    var estCostVnd: Double? = nil
    var imageSize: CGFloat = 96
    var showsChevron: Bool = true

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let matchPct {
                    Text("\(Int(matchPct.rounded()))% hợp gu")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: 0x2F6B43))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xE2F2E7), in: Capsule())
                }

                metaRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.Ghibli.straw)
            }
        }
        .padding(12)
        .background(Color(hex: 0xFAF6EE), in: shape)
        .overlay {
            shape.strokeBorder(Color.Ghibli.straw.opacity(0.65), lineWidth: 1.4)
        }
        .shadow(color: Color.Ghibli.wood.opacity(0.08), radius: 6, x: 0, y: 3)
        .contentShape(shape)
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0xEDE4D3)
                .overlay {
                    KFImage(imageURL)
                        .placeholder {
                            Text("🍲")
                                .font(.system(size: imageSize / 3))
                        }
                        .downsampling(size: CGSize(width: imageSize * 2.5, height: imageSize * 2.5))
                        .cacheOriginalImage()
                        .cancelOnDisappear(true)
                        .fade(duration: 0.15)
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let rank {
                Text("#\(rank)")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.Ghibli.wood.opacity(0.9), in: Capsule())
                    .padding(6)
            }
        }
    }

    @ViewBuilder
    private var metaRow: some View {
        let hasTime = (cookTimeMin ?? 0) > 0
        let hasCost = (estCostVnd ?? 0) > 0
        if hasTime || hasCost {
            HStack(spacing: 12) {
                if let cookTimeMin, hasTime {
                    Label("\(cookTimeMin) phút", systemImage: "clock")
                }
                if let estCostVnd, hasCost {
                    Label(Self.formatVND(estCostVnd), systemImage: "banknote")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.Ghibli.inkMuted)
        }
    }

    /// Làm tròn tới nghìn đồng: 65 400 → "65.000đ".
    static func formatVND(_ amount: Double) -> String {
        let rounded = Int((amount / 1000).rounded()) * 1000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
        return "\(formatted)đ"
    }
}

// MARK: - Khởi tạo từ model

extension DishCard {
    /// Món gợi ý từ `/api/v1/recommend`.
    init(dish: RankedDishDTO) {
        self.init(
            title: dish.title,
            imageURL: dish.imageURL,
            rank: dish.rank,
            matchPct: dish.matchPct,
            cookTimeMin: dish.cookTimeMin,
            estCostVnd: dish.estCostVnd
        )
    }

    /// Món đã lưu cục bộ.
    init(saved: SavedDish, imageSize: CGFloat = 96) {
        self.init(
            title: saved.title,
            imageURL: saved.imageURL,
            matchPct: saved.matchPct,
            cookTimeMin: saved.cookTimeMin,
            estCostVnd: saved.estCostVnd,
            imageSize: imageSize
        )
    }
}

#Preview {
    VStack(spacing: 14) {
        DishCard(
            title: "Thịt kho tiêu xanh",
            imageURL: nil,
            rank: 1,
            matchPct: 91,
            cookTimeMin: 30,
            estCostVnd: 65000
        )
        DishCard(
            saved: SavedDish(dishId: "2", title: "Canh chua cá lóc", cookTimeMin: 25, estCostVnd: 50000, matchPct: 84),
            imageSize: 72
        )
    }
    .padding()
    .background(Color.Ghibli.cream)
}
