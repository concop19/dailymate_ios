//
//  HomeSearchOptionsView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import SwiftUI

struct HomeSearchOptionsView: View {
    let selectedCategory: HomeFeature.DishCategory
    let selectedCookingMethods: Set<HomeFeature.CookingMethod>
    let onSelectCategory: (HomeFeature.DishCategory) -> Void
    let onToggleCookingMethod: (HomeFeature.CookingMethod) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TÙY CHỌN TÌM KIẾM")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(Color.Ghibli.inkLabel)

            // Loại món: Tất cả · Canh · Món mặn
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(HomeFeature.DishCategory.allCases) { category in
                        filterChip(
                            emoji: category.emoji,
                            title: category.title,
                            isSelected: category == selectedCategory
                        ) {
                            onSelectCategory(category)
                        }
                    }
                }
            }

            // Dụng cụ / cách nấu (cố định 2 hàng: Hàng 1 dụng cụ, Hàng 2 cách nấu)
            VStack(alignment: .leading, spacing: 10) {
                Text("Dụng cụ / cách nấu")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkDark)

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach([HomeFeature.CookingMethod.riceCooker, .pan, .airFryer]) { method in
                                filterChip(
                                    emoji: method.emoji,
                                    title: method.title,
                                    isSelected: selectedCookingMethods.contains(method)
                                ) {
                                    onToggleCookingMethod(method)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach([HomeFeature.CookingMethod.stirFry, .braise, .steam, .boil]) { method in
                                filterChip(
                                    emoji: method.emoji,
                                    title: method.title,
                                    isSelected: selectedCookingMethods.contains(method)
                                ) {
                                    onToggleCookingMethod(method)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(
        emoji: String,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.Ghibli.inkDark)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            // Chưa chọn: trong suốt, lộ nền Home. Đã chọn: nền kem trắng.
            .background(
                isSelected ? Color(hex: 0xFAF5EA) : Color.clear,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.Ghibli.wood.opacity(0.6) : Color.Ghibli.straw.opacity(0.85),
                        lineWidth: isSelected ? 1.8 : 1.4
                    )
            }
            .shadow(color: Color.Ghibli.wood.opacity(isSelected ? 0.14 : 0), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.ghibliPress)
    }
}

#Preview {
    HomeSearchOptionsView(
        selectedCategory: .savory,
        selectedCookingMethods: [.riceCooker, .pan],
        onSelectCategory: { _ in },
        onToggleCookingMethod: { _ in }
    )
    .padding()
    .background(Color.Ghibli.cream)
}
