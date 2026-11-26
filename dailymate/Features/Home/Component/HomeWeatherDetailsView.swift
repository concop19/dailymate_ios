//
//  HomeWeatherDetailsView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import SwiftUI

struct HomeWeatherDetailsView: View {
    let isExpanded: Bool
    let humidityText: String
    let windSpeedText: String
    let pressureText: String
    let aqiValue: Int
    let aqiLabel: String
    let aqiSeverity: HomeFeature.MetricSeverity
    let aqiProgress: Double
    let uvFormattedText: String
    let uvLevelText: String
    let uvSeverity: HomeFeature.MetricSeverity
    let uvProgress: Double
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Text(isExpanded ? "Thu gọn" : "Độ ẩm, gió, không khí, UV")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Color.Ghibli.inkLabel)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if !isExpanded {
                Rectangle()
                    .fill(Color.Ghibli.inkMuted.opacity(0.22))
                    .frame(height: 1)
            }

            if isExpanded {
                VStack(spacing: 14) {
                    // 3 thẻ gỗ: Độ ẩm · Sức gió · Áp suất
                    HStack(spacing: 10) {
                        woodMetricCard(
                            icon: "drop.fill",
                            title: "ĐỘ ẨM",
                            value: humidityText,
                            unit: "%"
                        )
                        woodMetricCard(
                            icon: "wind",
                            title: "SỨC GIÓ",
                            value: windSpeedText,
                            unit: "km/h"
                        )
                        woodMetricCard(
                            icon: "arrow.down.to.line",
                            title: "ÁP SUẤT",
                            value: pressureText,
                            unit: "hPa"
                        )
                    }

                    // Thẻ giấy: Chất lượng không khí (AQI)
                    paperGaugeCard(
                        icon: "leaf.fill",
                        title: "Chất lượng không khí",
                        badgeText: aqiLabel,
                        subtitle: "Mức hiện tại",
                        valueText: "AQI \(aqiValue)",
                        progress: aqiProgress,
                        accentColor: severityColor(aqiSeverity),
                        ticks: ["0", "50", "100", "150", "200", "300"]
                    )

                    // Thẻ giấy: Chỉ số UV
                    paperGaugeCard(
                        icon: "sun.max.fill",
                        title: "Chỉ số UV",
                        badgeText: "\(uvFormattedText) · \(uvLevelText)",
                        subtitle: "Vị trí trên thang đo",
                        valueText: "UV \(uvFormattedText)",
                        progress: uvProgress,
                        accentColor: severityColor(uvSeverity),
                        ticks: ["0", "2", "5", "7", "10", "11+"]
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Wood Metric Card

    private func woodMetricCard(
        icon: String,
        title: String,
        value: String,
        unit: String
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color(hex: 0xF5ECDD))

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(unit)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(hex: 0xEFE4D2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background {
            Color(hex: 0x9C7D5A)
                .overlay {
                    GhibliTexture.wood.image
                        .resizable()
                        .scaledToFill()
                        .opacity(0.65)
                }
                .overlay {
                    Color(hex: 0x6D5236).opacity(0.32)
                }
        }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(Color(hex: 0x6F5336).opacity(0.75), lineWidth: 1.4)
        }
        .shadow(color: Color.Ghibli.wood.opacity(0.14), radius: 6, x: 0, y: 3)
    }

    // MARK: - Paper Gauge Card

    private func paperGaugeCard(
        icon: String,
        title: String,
        badgeText: String,
        subtitle: String,
        valueText: String,
        progress: Double,
        accentColor: Color,
        ticks: [String]
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkLabel)

                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.Ghibli.inkDark)

                Spacer()

                Text(badgeText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(accentColor.opacity(0.65), lineWidth: 1.2)
                    }
            }

            HStack(alignment: .firstTextBaseline) {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.Ghibli.inkMuted)

                Spacer()

                Text(valueText)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(accentColor)
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                GeometryReader { proxy in
                    let width = max(proxy.size.width, 1)
                    let clamped = min(max(progress, 0), 1)
                    let thumbSize: CGFloat = 18
                    let fillWidth = max(thumbSize / 2, width * CGFloat(clamped))

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.Ghibli.straw.opacity(0.28))
                            .frame(height: 8)

                        Capsule()
                            .fill(accentColor)
                            .frame(width: fillWidth, height: 8)

                        Circle()
                            .fill(Color(hex: 0xFFFDF8))
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay {
                                Circle()
                                    .strokeBorder(accentColor, lineWidth: 3.5)
                            }
                            .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                            .offset(x: min(max(fillWidth - thumbSize / 2, 0), width - thumbSize))
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 20)

                HStack {
                    ForEach(Array(ticks.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.Ghibli.inkMuted)
                            .monospacedDigit()
                        if index < ticks.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            Color(hex: 0xFAF3E0)
                .overlay {
                    GhibliTexture.paper.image
                        .resizable()
                        .scaledToFill()
                        .opacity(0.45)
                }
        }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(Color.Ghibli.straw.opacity(0.85), lineWidth: 1.5)
        }
        .shadow(color: Color.Ghibli.wood.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func severityColor(_ severity: HomeFeature.MetricSeverity) -> Color {
        switch severity {
        case .good:     Color(hex: 0x3D6B48)
        case .moderate: Color(hex: 0x9E6B1E)
        case .high:     Color(hex: 0xC25E28)
        case .veryHigh: Color(hex: 0xA8332A)
        }
    }
}

#Preview {
    ScrollView {
        HomeWeatherDetailsView(
            isExpanded: true,
            humidityText: "66",
            windSpeedText: "1,8",
            pressureText: "1015",
            aqiValue: 60,
            aqiLabel: "Trung bình",
            aqiSeverity: .moderate,
            aqiProgress: 0.2,
            uvFormattedText: "0,0",
            uvLevelText: "Thấp",
            uvSeverity: .good,
            uvProgress: 0,
            onToggle: {}
        )
        .padding()
    }
    .background(Color.Ghibli.cream)
}
