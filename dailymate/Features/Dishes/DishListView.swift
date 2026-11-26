//
//  DishListView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct DishListView: View {
    @Bindable var store: StoreOf<DishListFeature>

    var body: some View {
        Group {
            if store.isLoading {
                VStack(spacing: 18) {
                    MascotBanner(
                        message: "DailyMate đang tìm những món hợp khẩu vị và thời tiết nhất...",
                        animationName: "Cute cat works",
                        mascotSize: 88
                    )
                    ProgressView()
                        .tint(Color.Ghibli.wood)
                        .scaleEffect(1.2)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.errorMessage, store.dishes.isEmpty {
                VStack(spacing: 16) {
                    OnboardingErrorText(error)
                    Button("Thử lại") {
                        store.send(.retryTapped)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.wood)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.dishes.isEmpty {
                VStack(spacing: 14) {
                    Text("🍲")
                        .font(.system(size: 52))
                    Text("Chưa tìm thấy món phù hợp")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkDark)
                    Button("Thử lại") {
                        store.send(.retryTapped)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.wood)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if let warningCount = store.basketWarningCount {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(Color.Ghibli.wood)
                                Text("Chỉ có \(warningCount) món khớp hết nguyên liệu bạn chọn.")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.Ghibli.inkLabel)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: 0xFFF8EA), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.Ghibli.straw.opacity(0.65), lineWidth: 1.2)
                            }
                        }

                        if store.totalDishes > 0 {
                            Text("Tìm thấy \(store.totalDishes) món phù hợp")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.Ghibli.inkMuted)
                        }

                        ForEach(store.dishes) { dish in
                            dishCard(dish)
                        }

                        if let error = store.errorMessage {
                            OnboardingErrorText(error)
                        }

                        if store.hasNextPage {
                            Button {
                                store.send(.loadNextPageTapped)
                            } label: {
                                HStack(spacing: 8) {
                                    if store.isLoadingMore {
                                        ProgressView()
                                            .tint(Color.Ghibli.wood)
                                            .scaleEffect(0.85)
                                    }
                                    Text(store.isLoadingMore ? "Đang tải thêm..." : "Xem thêm món")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color.Ghibli.inkDark)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: 0xFAF5EA), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.Ghibli.straw.opacity(0.8), lineWidth: 1.4)
                                }
                            }
                            .buttonStyle(.ghibliPress)
                            .disabled(store.isLoadingMore)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { OnboardingBackground() }
        .navigationTitle("Gợi ý món ăn")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func dishCard(_ dish: RankedDishDTO) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        return Button {
            store.send(.dishTapped(dish))
        } label: {
            HStack(spacing: 14) {
                ZStack(alignment: .topLeading) {
                    Color(hex: 0xEDE4D3)
                        .overlay {
                            KFImage(dish.imageURL)
                                .placeholder {
                                    Text("🍲")
                                        .font(.system(size: 32))
                                }
                                .downsampling(size: CGSize(width: 240, height: 240))
                                .cacheOriginalImage()
                                .cancelOnDisappear(true)
                                .fade(duration: 0.15)
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if let rank = dish.rank {
                        Text("#\(rank)")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.Ghibli.wood.opacity(0.9), in: Capsule())
                            .padding(6)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(dish.title)
                        .font(.system(.headline, design: .serif, weight: .bold))
                        .foregroundStyle(Color.Ghibli.inkDark)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let match = dish.matchPct {
                        Text("\(Int(match.rounded()))% hợp gu")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0x2F6B43))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xE2F2E7), in: Capsule())
                    }

                    HStack(spacing: 12) {
                        if let cookTime = dish.cookTimeMin, cookTime > 0 {
                            Label("\(cookTime) phút", systemImage: "clock")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.Ghibli.inkMuted)
                        }

                        if let cost = dish.estCostVnd, cost > 0 {
                            Label(formatVND(cost), systemImage: "banknote")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.Ghibli.inkMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.Ghibli.straw)
            }
            .padding(12)
            .background(Color(hex: 0xFAF6EE), in: shape)
            .overlay {
                shape.strokeBorder(Color.Ghibli.straw.opacity(0.65), lineWidth: 1.4)
            }
            .shadow(color: Color.Ghibli.wood.opacity(0.08), radius: 6, x: 0, y: 3)
            .contentShape(shape)
        }
        .buttonStyle(.ghibliPress)
    }

    private func formatVND(_ amount: Double) -> String {
        let rounded = Int((amount / 1000).rounded()) * 1000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
        return "\(formatted)đ"
    }
}

#Preview {
    NavigationStack {
        DishListView(
            store: Store(
                initialState: DishListFeature.State(
                    baseParams: SearchParamsBuilder.base(
                        profile: nil,
                        lat: 16.05,
                        lon: 108.21
                    )
                )
            ) {
                DishListFeature()
            }
        )
    }
}
