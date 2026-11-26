//
//  HomeWeatherHeroView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import Lottie
import SwiftUI

struct HomeWeatherHeroView: View {
    let weatherIcon: String
    let temperatureText: String
    let conditionText: String
    let feelsLikeText: String
    let seasonTitle: String
    let seasonEmoji: String
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 10) {
            // Mascot Lazy Cat + Icon thời tiết trong vòng tròn mờ
            HStack(spacing: 14) {
                LottieView(animation: .named("Lazy cat"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .accessibilityHidden(true)

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 118, height: 118)

                    Image(systemName: weatherIcon)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 56, weight: .medium))
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                }
            }

            // Nhiệt độ lớn
            HStack(alignment: .top, spacing: 2) {
                Text(temperatureText)
                    .font(.system(size: 50, weight: .bold, design: .serif))
                    .foregroundStyle(Color.Ghibli.inkDark)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("°C")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.Ghibli.inkLabel)
                    .padding(.top, 12)
            }
            .overlay(alignment: .trailing) {
                if isLoading {
                    ProgressView()
                        .tint(Color.Ghibli.wood)
                        .offset(x: 28)
                }
            }

            // Tình trạng thời tiết + Huy hiệu mùa
            HStack(spacing: 22) {
                VStack(spacing: 4) {
                    Text(conditionText)
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(Color.Ghibli.inkDark)

                    Text(feelsLikeText)
                        .font(.subheadline)
                        .foregroundStyle(Color.Ghibli.inkMuted)
                }

                ZStack {
                    Circle()
                        .fill(Color(hex: 0xEADFD3).opacity(0.45))
                        .frame(width: 78, height: 78)
                        .overlay {
                            Circle()
                                .strokeBorder(Color(hex: 0xE1B3BA).opacity(0.85), lineWidth: 2)
                        }

                    VStack(spacing: 2) {
                        Text(seasonEmoji)
                            .font(.system(size: 24))
                        Text(seasonTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.Ghibli.inkDark)
                    }
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeWeatherHeroView(
        weatherIcon: "cloud.sun.fill",
        temperatureText: "30",
        conditionText: "Có mây",
        feelsLikeText: "Cảm giác như 31°C",
        seasonTitle: "Mùa thu",
        seasonEmoji: "🍂",
        isLoading: false
    )
    .padding()
    .background(Color.Ghibli.cream)
}
