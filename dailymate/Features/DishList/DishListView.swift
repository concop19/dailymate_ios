//
//  DishListView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
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
                    ErrorText(error)
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
                            Button {
                                store.send(.dishTapped(dish))
                            } label: {
                                DishCard(dish: dish)
                            }
                            .buttonStyle(.ghibliPress)
                        }

                        if let error = store.errorMessage {
                            ErrorText(error)
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
        .background { PaperBackground() }
        .navigationTitle("Gợi ý món ăn")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
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
