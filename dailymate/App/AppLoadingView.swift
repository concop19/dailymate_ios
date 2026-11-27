//
//  AppLoadingView.swift
//  dailymate
//

import Lottie
import SwiftUI

/// Màn chờ khi mở app (kiểm tra phiên đăng nhập / tải hồ sơ).
/// Giữ bố cục cũ: nền gỗ + tấm giấy kem + mèo `cat1` + lời nhắn — style lại cho mềm và gọn hơn.
struct AppLoadingView: View {
    var message: String = "Để DailyMate nấu cho bạn\n1 món ngon nhé"

    @State private var appeared = false

    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()

            paperCard
                .padding(.horizontal, 36)
                // Chỉ nhún nhẹ, không fade từ 0 — màn chờ thường rất ngắn nên fade sẽ làm thẻ trông mờ.
                .scaleEffect(appeared ? 1 : 0.96)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var paperCard: some View {
        VStack(spacing: 0) {
            LottieView(animation: .named("cat1"))
                .playing(loopMode: .loop)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .accessibilityHidden(true)

            Text("DailyMate")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Color.Ghibli.inkDark)
                .padding(.top, 4)

            ornament
                .padding(.top, 8)

            Text(message)
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundStyle(Color.Ghibli.inkBody)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 14)

            LoadingDots()
                .padding(.top, 22)
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 32)
        .frame(maxWidth: 340)
        .background {
            GhibliTexture.paper.image
                .resizable()
                .scaledToFill()
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.Ghibli.straw.opacity(0.85), lineWidth: 1.5)
        }
        .overlay {
            // Viền chỉ khâu bên trong cho cảm giác giấy thủ công.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    Color.Ghibli.straw.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                )
                .padding(8)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 18, y: 10)
        .shadow(color: Color.Ghibli.wood.opacity(0.25), radius: 4, y: 2)
    }

    private var ornament: some View {
        HStack(spacing: 8) {
            Capsule().fill(Color.Ghibli.straw.opacity(0.7)).frame(width: 28, height: 1.5)
            Image(systemName: "leaf.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.Ghibli.straw)
            Capsule().fill(Color.Ghibli.straw.opacity(0.7)).frame(width: 28, height: 1.5)
        }
        .accessibilityHidden(true)
    }
}

/// Ba chấm nhún nhảy lần lượt — chỉ báo đang tải.
private struct LoadingDots: View {
    private let colors: [Color] = [Color.Ghibli.wood, Color.Ghibli.straw, Color.Ghibli.sky]

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = t * 4 - Double(index) * 0.6
                    let lift = max(0, sin(phase))
                    Circle()
                        .fill(colors[index])
                        .frame(width: 10, height: 10)
                        .offset(y: -8 * lift)
                        .opacity(0.55 + 0.45 * lift)
                }
            }
            .frame(height: 20)
        }
        .accessibilityLabel("Đang tải")
    }
}

#Preview {
    AppLoadingView()
}
