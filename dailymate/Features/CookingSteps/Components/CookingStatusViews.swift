//
//  CookingStatusViews.swift
//  dailymate
//

import Lottie
import SwiftUI

/// Khối "đang tải các bước nấu".
struct CookingLoadingBlock: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.Ghibli.wood)
                .controlSize(.large)
            Text("Đang tải các bước nấu…")
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

/// Khối báo lỗi khi tải bước nấu (kèm nút thử lại và link công thức gốc nếu có).
struct CookingErrorBlock: View {
    let error: CookingStepsFeature.StepsError
    let sourceURL: URL?
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            LottieView(animation: .named("cat_gosh"))
                .playing(loopMode: .loop)
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
            Text(error.title)
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color.Ghibli.inkDark)
                .multilineTextAlignment(.center)
            Text(error.message)
                .font(.subheadline)
                .foregroundStyle(Color.Ghibli.inkMuted)
                .multilineTextAlignment(.center)
            if error.canRetry {
                GhibliPrimaryButton(title: "Thử lại", icon: "arrow.clockwise", action: onRetry)
                    .padding(.top, 6)
            }
            CookingSourceLink(url: sourceURL)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

/// Link "Xem công thức gốc" — không hiện gì nếu `url` là nil.
struct CookingSourceLink: View {
    let url: URL?
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let url {
            Button {
                openURL(url)
            } label: {
                Label("Xem công thức gốc", systemImage: "link")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.skyDeep)
            }
            .padding(.vertical, 6)
        }
    }
}
