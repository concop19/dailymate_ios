//
//  MascotBanner.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import Lottie
import SwiftUI
import UIKit

/// Mascot hoạt hình Lottie kèm bong bóng thoại dùng chung cho nhiều màn hình.
/// Cho phép tuỳ chỉnh:
/// - `message`: Nội dung lời thoại.
/// - `icon`: Emoji (vd: `"🍳"`, `"✨"`) hoặc tên SF Symbol (vd: `"sparkles"`, `"leaf.fill"`) đi kèm lời thoại.
/// - `animationName`: Tên file JSON Lottie trong bundle (mặc định là mèo cười).
/// - `loopMode` & `mascotSize`: Chế độ lặp và kích thước mascot.
struct MascotBanner: View {
  let message: String
  var icon: String? = nil
  var animationName: String = "Cat laughing loudly. HahahahLOL emojisticker animation"
  var loopMode: LottieLoopMode = .loop
  var mascotSize: CGFloat = 72

  var body: some View {
    HStack(alignment: .bottom, spacing: 10) {
      LottieView(animation: .named(animationName))
        .playing(loopMode: loopMode)
        .resizable()
        .scaledToFit()
        .frame(width: mascotSize, height: mascotSize)
        .padding(.bottom, -4)
        .accessibilityHidden(true)

      HStack(alignment: .firstTextBaseline, spacing: 8) {
        if let icon, !icon.isEmpty {
          iconView(icon)
        }

        Text(message)
          .font(.subheadline)
          .foregroundStyle(Color.Ghibli.inkBody)
          .lineSpacing(4)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .background(Color.Ghibli.cream.opacity(0.92), in: .rect(cornerRadius: 16))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(Color.Ghibli.straw, lineWidth: 1.5)
      }
      .padding(.bottom, 10)
      .contentTransition(.opacity)
    }
    .padding(.horizontal, 4)
  }

  @ViewBuilder
  private func iconView(_ nameOrEmoji: String) -> some View {
    if UIImage(systemName: nameOrEmoji) != nil {
      Image(systemName: nameOrEmoji)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.Ghibli.wood)
    } else {
      Text(nameOrEmoji)
        .font(.subheadline)
    }
  }
}

typealias AuthMascotBanner = MascotBanner

#Preview("Kèm Icon & Lottie tuỳ chọn") {
  VStack(spacing: 20) {
    MascotBanner(
      message: "Meo~ Hôm nay mình nấu món gì ngon nhỉ?",
      icon: "🍳"
    )

    MascotBanner(
      message: "Đang tìm công thức phù hợp cho bạn...",
      icon: "sparkles",
      animationName: "Cute cat works"
    )
  }
  .padding()
  .background(BackgroundView())
}
