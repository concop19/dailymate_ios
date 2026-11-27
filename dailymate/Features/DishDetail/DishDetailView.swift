//
//  DishDetailView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI

struct DishDetailView: View {
    @Bindable var store: StoreOf<DishDetailFeature>
    @Namespace private var tabNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        heroHeader

                        VStack(spacing: 14) {
                            summaryCard
                            segmentTabs
                            tabContent
                        }
                        .padding(.horizontal, 16)
                        .offset(y: -24)
                        .padding(.bottom, 12)
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)

                bottomBar
            }

            if let toast = store.toastMessage {
                Text(toast)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.Ghibli.inkDark.opacity(0.92), in: Capsule())
                    .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
                    .padding(.bottom, 136)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.toastMessage)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { PaperBackground() }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Hero Image + Floating Buttons

    private var heroHeader: some View {
        ZStack(alignment: .top) {
            Color(hex: 0xEDE4D3)
                .overlay {
                    KFImage(store.dish.imageURL)
                        .placeholder {
                            Text("🍜")
                                .font(.system(size: 64))
                        }
                        .downsampling(size: CGSize(width: 900, height: 675))
                        .cacheOriginalImage()
                        .cancelOnDisappear(true)
                        .fade(duration: 0.2)
                        .resizable()
                        .scaledToFill()
                }
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .clipped()

            HStack(alignment: .top) {
                roundIconButton(
                    systemName: "chevron.left",
                    tint: Color.Ghibli.inkDark,
                    accessibilityLabel: "Quay lại"
                ) {
                    store.send(.backTapped)
                }

                Spacer()

                roundIconButton(
                    systemName: store.isSaved ? "bookmark.fill" : "bookmark",
                    tint: store.isSaved ? Color(hex: 0xF59E0B) : Color.Ghibli.wood,
                    accessibilityLabel: store.isSaved ? "Bỏ lưu món" : "Lưu món"
                ) {
                    store.send(.toggleSaveTapped)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
        }
    }

    private func roundIconButton(
        systemName: String,
        tint: Color,
        enabled: Bool = true,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.92), in: Circle())
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(.ghibliPress)
        .disabled(!enabled)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        PaperCard(cornerRadius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.dish.title)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    statItem(emoji: "⏱", value: cookTimeShortText, label: "Thời gian")
                    Spacer()
                    statItem(emoji: "⭐", value: "\(store.matchPct)%", label: "Hợp gu")
                    Spacer()
                    statItem(emoji: "💰", value: priceShortText, label: "Giá ước tính")
                }
                .padding(.horizontal, 6)
            }
        }
    }

    private func statItem(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji)
                .font(.subheadline)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkDark)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.Ghibli.inkMuted)
        }
        .frame(minWidth: 76)
    }

    // MARK: - Segment Tabs

    private var segmentTabs: some View {
        HStack(spacing: 4) {
            ForEach(DishDetailFeature.Tab.allCases) { tab in
                let isSelected = store.selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        store.send(.tabSelected(tab))
                    }
                } label: {
                    Text(tab.title)
                        .font(.footnote.weight(isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? Color.Ghibli.inkDark : Color.Ghibli.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.Ghibli.cream)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.Ghibli.straw.opacity(0.8), lineWidth: 1.2)
                                    }
                                    .shadow(color: Color.Ghibli.wood.opacity(0.1), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "dishDetailTab", in: tabNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: 0xEAE0CC), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.Ghibli.straw.opacity(0.5), lineWidth: 1)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch store.selectedTab {
        case .ingredients:
            DishDetailIngredientsView(
                isLoading: store.isLoadingDetail,
                errorMessage: store.errorMessage,
                missingIngredients: store.dish.missingIngredients,
                mainIngredients: store.mainIngredients,
                sideIngredients: store.sideIngredients,
                pickedIds: store.pickedIngredientIds,
                onRetry: { store.send(.retryDetailTapped) }
            )
        case .why:
            DishDetailRecommendedView(
                why: store.dish.why,
                legacyExplanation: store.dish.explanation
            )
        case .info:
            DishDetailInfoView(
                dish: store.dish,
                detail: store.detail,
                matchPct: store.matchPct
            )
        }
    }

    // MARK: - Curved Bottom Bar

    private var bottomBar: some View {
        ZStack(alignment: .top) {
            CurvedDomeBarShape()
                .fill(Color(hex: 0xFAF5EA))
                .overlay {
                    CurvedDomeBarShape()
                        .stroke(Color.Ghibli.straw.opacity(0.65), lineWidth: 1)
                }
                .shadow(color: Color.Ghibli.wood.opacity(0.1), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .top) {
                feedbackButton(
                    action: .eaten,
                    iconName: "icon_dish_eaten_3d",
                    defaultTitle: "Đã ăn"
                )
                .frame(width: 94)

                Spacer()

                feedbackButton(
                    action: .skipped,
                    iconName: "icon_dish_skip_3d",
                    defaultTitle: "Bỏ qua"
                )
                .frame(width: 94)
            }
            .padding(.horizontal, 12)
            .padding(.top, 32)

            Button {
                store.send(.cookNowTapped)
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.Ghibli.cream)
                            .frame(width: 76, height: 76)
                            .shadow(color: Color.Ghibli.wood.opacity(0.15), radius: 6, y: 2)

                        Image("icon_dish_cook_3d")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                    }

                    Text("Nấu ngay")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkDark)
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
            }
            .buttonStyle(.ghibliPress)
        }
        .frame(height: 118)
    }

    private func feedbackButton(
        action: DishFeedbackAction,
        iconName: String,
        defaultTitle: String
    ) -> some View {
        let state = store.feedbackStates[action] ?? .idle
        let labelText: String = switch state {
        case .done:  "Đã ghi nhận"
        case .error: "Lỗi"
        default:     defaultTitle
        }

        return Button {
            store.send(.sendFeedback(action))
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if state == .loading {
                        ProgressView()
                            .tint(Color.Ghibli.wood)
                    } else {
                        Image(iconName)
                            .resizable()
                            .scaledToFit()
                            .opacity(state == .done ? 0.65 : 1)
                    }
                }
                .frame(width: 50, height: 50)

                Text(labelText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(state == .error ? Color(hex: 0xB5543C) : Color.Ghibli.inkLabel)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.ghibliPress)
        .disabled(state == .loading || state == .done)
    }

    // MARK: - Formatting

    private var cookTimeShortText: String {
        if let mins = store.dish.cookTimeMin ?? store.detail?.cookTimeMinutes, mins > 0 {
            return "\(mins) phút"
        }
        return "—"
    }

    private var priceShortText: String {
        guard let amount = store.dish.estCostVnd ?? store.detail?.estCostVnd, amount > 0 else { return "—" }
        let rounded = Int((amount / 1000).rounded()) * 1000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formatted = formatter.string(from: NSNumber(value: rounded)) ?? "\(rounded)"
        return "\(formatted)đ"
    }
}

// MARK: - Curved Dome Bottom Bar Shape

private struct CurvedDomeBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sideTop: CGFloat = 36
        let peakTop: CGFloat = 4
        let halfDome: CGFloat = 74
        let centerX = rect.midX

        var path = Path()
        path.move(to: CGPoint(x: 0, y: sideTop))
        path.addLine(to: CGPoint(x: centerX - halfDome, y: sideTop))
        path.addCurve(
            to: CGPoint(x: centerX, y: peakTop),
            control1: CGPoint(x: centerX - 54, y: sideTop),
            control2: CGPoint(x: centerX - 52, y: peakTop)
        )
        path.addCurve(
            to: CGPoint(x: centerX + halfDome, y: sideTop),
            control1: CGPoint(x: centerX + 52, y: peakTop),
            control2: CGPoint(x: centerX + 54, y: sideTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: sideTop))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + 60))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY + 60))
        path.closeSubpath()
        return path
    }
}

#Preview {
    DishDetailView(
        store: Store(
            initialState: DishDetailFeature.State(
                dish: RankedDishDTO(
                    dishId: "10131383",
                    rank: 1,
                    finalScore: 0.91,
                    matchPct: 91,
                    title: "Thịt kho tiêu xanh",
                    imageUrl: nil,
                    nation: "vietnam",
                    cookTimeMin: 30,
                    estCostVnd: 65000,
                    estCostLevel: 2,
                    missingIngredients: ["Tiêu xanh"]
                ),
                pickedIngredientIds: [102, 301]
            )
        ) {
            DishDetailFeature()
        }
    )
}
