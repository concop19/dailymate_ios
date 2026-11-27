//
//  IngredientSuggestView.swift
//  dailymate
//
//  Created by ManhLe on 11/23/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct IngredientSuggestView: View {
    @Bindable var store: StoreOf<IngredientSuggestFeature>
     private let columns = [
        GridItem(.flexible(),spacing: 12),
        GridItem(.flexible(),spacing: 12)
     ]
    var body: some View {
        Group {
            if store.isLoading {
                VStack(spacing: 18) {
                    MascotBanner(
                        message: "Đang chọn nguyên liệu hợp thời tiết và khẩu vị của bạn...",
                        animationName: "Cute cat works",
                        mascotSize: 88
                    )
                    ProgressView()
                        .tint(Color.Ghibli.wood)
                        .scaleEffect(1.2)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.errorMessage {
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
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(store.sections) { section in
                            if !section.items.isEmpty {
                                sectionView(section)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { PaperBackground() }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationTitle("Gợi ý nguyên liệu")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func sectionView(_ section: SuggestSectionDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sectionTitle(for: section.key))
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkDark)

           
            
            LazyVGrid(columns: columns, spacing:12)
            {
                ForEach(section.items) { item in
                    ingredientCard(item, isSelected: store.selectedIds.contains(item.id))
                }
                
            }
        }
    }

    private func ingredientCard(_ item: SuggestedIngredientDTO, isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return Button {
            store.send(.ingredientToggled(item.id))
        } label: {
            ZStack {
                // Lớp 1: Ảnh nền tràn viền (256px thumb)
                Color(hex: 0xEDE4D3)
                    .overlay {
                        KFImage(item.iconURL)
                            .placeholder {
                                Image(systemName: "leaf.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.Ghibli.inkMuted.opacity(0.6))
                            }
                            .downsampling(size: CGSize(width: 256, height: 256))
                            .cacheOriginalImage()
                            .cancelOnDisappear(true)
                            .fade(duration: 0.15)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()

                // Lớp 2: Gradient tối dần xuống đáy giúp chữ trắng luôn dễ đọc
                LinearGradient(
                    colors: [.clear, .black.opacity(0.25), .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Lớp 3: Dấu tick ở góc trên-phải & Tên + thông tin ở góc dưới-trái
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.Ghibli.cream : .white.opacity(0.85))
                            .background {
                                if isSelected {
                                    Circle()
                                        .fill(Color.Ghibli.wood)
                                        .padding(2)
                                } else {
                                    Circle()
                                        .fill(.black.opacity(0.25))
                                        .padding(2)
                                }
                            }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if item.dishCount > 0 {
                            Text("\(item.dishCount) món")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        if let firstReason = item.reasons.first?.label, !firstReason.isEmpty {
                            Text(firstReason)
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0xF5EDDC).opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    isSelected ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.45),
                    lineWidth: isSelected ? 2.5 : 1
                )
            }
            .shadow(color: Color.Ghibli.wood.opacity(isSelected ? 0.22 : 0.1), radius: 6, x: 0, y: 3)
            .contentShape(shape)
        }
        .buttonStyle(.ghibliPress)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                store.send(.loadingMoreTapped)
            } label: {
                HStack(spacing: 6) {
                    if store.isLoadingMore {
                        ProgressView()
                            .tint(Color.Ghibli.wood)
                            .scaleEffect(0.85)
                    }
                    Text(store.isLoadingMore ? "Đang tải..." : "Gợi ý khác")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkLabel)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .background(Color(hex: 0xFAF5EA), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.Ghibli.straw.opacity(0.8), lineWidth: 1.4)
                }
            }
            .buttonStyle(.ghibliPress)
            .disabled(store.isLoadingMore)

            Button {
                store.send(.continueButtonTapped)
            } label: {
                Text(store.selectedCount > 0 ? "Tìm món (\(store.selectedCount))" : "Tìm món ngay")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.Ghibli.wood, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.ghibliPress)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.Ghibli.cream.opacity(0.95))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.Ghibli.straw.opacity(0.25))
                .frame(height: 1)
        }
    }

    private func sectionTitle(for key: String) -> String {
        switch key.lowercased() {
        case "protein", "meat", "main": "Đạm chính"
        case "vegetable", "veggies", "veg": "Rau củ"
        case "seafood": "Hải sản"
        case "spice", "herb", "seasoning": "Gia vị & Rau thơm"
        case "carb", "starch": "Tinh bột"
        default: key.capitalized
        }
    }
}

#Preview {
    NavigationStack {
        IngredientSuggestView(
            store: Store(
                initialState: IngredientSuggestFeature.State(
                    searchParams: SearchParamsBuilder.base(
                        profile: nil,
                        lat: 16.05,
                        lon: 108.21
                    )
                )
            ) {
                IngredientSuggestFeature()
            }
        )
    }
}
