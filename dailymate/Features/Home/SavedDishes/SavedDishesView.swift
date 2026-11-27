//
//  SavedDishesView.swift
//  dailymate
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct SavedDishesView: View {
    let store: StoreOf<SavedDishesFeature>

    var body: some View {
        VStack(spacing: 0) {
            header

            if store.dishes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.dishes) { dish in
                        Button {
                            store.send(.dishTapped(dish))
                        } label: {
                            SavedDishRow(dish: dish)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.send(.deleteTapped(dish.id), animation: .default)
                            } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: 0xFAF5EA))
        .onAppear { store.send(.onAppear) }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(Color(hex: 0xF59E0B))
            Text("Món đã lưu")
                .font(.system(.headline, design: .serif, weight: .bold))
                .foregroundStyle(Color.Ghibli.inkDark)
            Spacer()
            Text("\(store.dishes.count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.Ghibli.wood)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.Ghibli.cream, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🔖")
                .font(.system(size: 36))
            Text("Chưa có món nào được lưu")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.Ghibli.inkLabel)
            Text("Nhấn biểu tượng lưu ở màn chi tiết món để thêm vào đây.")
                .font(.caption)
                .foregroundStyle(Color.Ghibli.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
    }
}

private struct SavedDishRow: View {
    let dish: SavedDish

    var body: some View {
        HStack(spacing: 12) {
            Color(hex: 0xEDE4D3)
                .overlay {
                    KFImage(dish.imageURL)
                        .placeholder {
                            Text("🍲").font(.system(size: 24))
                        }
                        .downsampling(size: CGSize(width: 160, height: 160))
                        .cacheOriginalImage()
                        .cancelOnDisappear(true)
                        .fade(duration: 0.15)
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(dish.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .lineLimit(2)
                if let mins = dish.cookTimeMin, mins > 0 {
                    Text("⏱ \(mins) phút")
                        .font(.caption)
                        .foregroundStyle(Color.Ghibli.inkMuted)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.Ghibli.straw)
        }
        .padding(10)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.Ghibli.straw.opacity(0.4), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    SavedDishesView(
        store: Store(initialState: SavedDishesFeature.State()) {
            SavedDishesFeature()
        }
    )
}
