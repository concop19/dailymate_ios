//
//  DishDetailIngredientsView.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import Kingfisher
import SwiftUI

/// Tab 0 — Nguyên liệu: banner cần mua thêm, lưới nguyên liệu chính và chip gia vị / nguyên liệu phụ.
struct DishDetailIngredientsView: View {
    let isLoading: Bool
    let errorMessage: String?
    let missingIngredients: [String]
    let mainIngredients: [DishIngredientDTO]
    let sideIngredients: [DishIngredientDTO]
    let pickedIds: Set<Int>
    let onRetry: () -> Void

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color.Ghibli.wood)
                        .scaleEffect(1.1)
                    Text("Đang tải nguyên liệu...")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.Ghibli.inkMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else if let error = errorMessage, mainIngredients.isEmpty, sideIngredients.isEmpty {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color(hex: 0xB5543C))
                        .multilineTextAlignment(.center)
                    Button("Thử lại", action: onRetry)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.wood)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if mainIngredients.isEmpty, sideIngredients.isEmpty {
                Text("🍱  Chưa có thông tin nguyên liệu")
                    .font(.subheadline)
                    .foregroundStyle(Color.Ghibli.inkMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    if !missingIngredients.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text("🛒")
                            Text("Cần mua thêm: \(missingIngredients.joined(separator: ", "))")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color(hex: 0x8A5D00))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(hex: 0xFFF4E5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(hex: 0xE9C08A), lineWidth: 1)
                        }
                    }

                    if !mainIngredients.isEmpty {
                        Text("Nguyên liệu chính")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.Ghibli.inkDark)

                        OnboardingFlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                            ForEach(mainIngredients) { ingredient in
                                mainIngredientCard(ingredient, have: pickedIds.contains(ingredient.id))
                            }
                        }
                    }

                    if !sideIngredients.isEmpty {
                        Text("Nguyên liệu phụ & Gia vị")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.Ghibli.inkDark)
                            .padding(.top, mainIngredients.isEmpty ? 0 : 4)

                        OnboardingFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                            ForEach(sideIngredients) { ingredient in
                                sideIngredientChip(ingredient, have: pickedIds.contains(ingredient.id))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func mainIngredientCard(_ ingredient: DishIngredientDTO, have: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return VStack(spacing: 5) {
            ZStack {
                Color(hex: 0xEDE4D3)
                KFImage(ingredient.iconURL)
                    .placeholder {
                        Text(categoryEmoji(ingredient.category))
                            .font(.system(size: 28))
                    }
                    .downsampling(size: CGSize(width: 140, height: 140))
                    .cacheOriginalImage()
                    .cancelOnDisappear(true)
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text((have ? "✓ " : "") + ingredient.name.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(have ? Color(hex: 0x275231) : Color.Ghibli.inkDark)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let qty = ingredient.quantityG, qty > 0 {
                Text("\(Int(qty.rounded()))g")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }
        }
        .padding(8)
        .frame(width: 96)
        .background(have ? Color(hex: 0xE9F6EC) : Color(hex: 0xFAF6EE), in: shape)
        .overlay {
            shape.strokeBorder(
                have ? Color(hex: 0x4E9A68) : Color.Ghibli.straw.opacity(0.75),
                lineWidth: have ? 1.8 : 1
            )
        }
    }

    private func sideIngredientChip(_ ingredient: DishIngredientDTO, have: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let qtyText = ingredient.quantityG.flatMap { $0 > 0 ? " · \(Int($0.rounded()))g" : nil } ?? ""
        return Text((have ? "✓ " : "") + ingredient.name.capitalized + qtyText)
            .font(.footnote.weight(have ? .semibold : .regular))
            .foregroundStyle(have ? Color(hex: 0x275231) : Color.Ghibli.inkBody)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(have ? Color(hex: 0xE9F6EC) : Color(hex: 0xFAF6EE), in: shape)
            .overlay {
                shape.strokeBorder(
                    have ? Color(hex: 0x4E9A68) : Color.Ghibli.straw.opacity(0.75),
                    lineWidth: 1
                )
            }
    }

    private func categoryEmoji(_ category: String?) -> String {
        switch category?.lowercased() {
        case "spice_herb", "gia vị": return "🧄"
        case "condiment", "dầu & mỡ": return "🫙"
        case "seafood", "hải sản": return "🦐"
        case "meat", "thịt": return "🥩"
        case "vegetable", "rau củ": return "🥦"
        default: return "🥬"
        }
    }
}
