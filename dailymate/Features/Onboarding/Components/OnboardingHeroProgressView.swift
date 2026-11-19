//
//  OnboardingHeroProgressView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Thanh hero phía trên màn Onboarding: nút back, nhãn "Bước X/5" và 5 vạch tiến trình.
/// `currentStage` được tính từ StackState: `path.count + 1`.
struct OnboardingHeroProgressView: View {
  let currentStage: Int
  var totalStages: Int = 5
  /// Phụ đề mở rộng, vd: "Thẻ 1/8" → hiển thị "Bước 4/5 · Thẻ 1/8".
  var detail: String? = nil
  var canGoBack: Bool = true
  var onBack: () -> Void = {}

  private var stageLabel: String {
    let base = "Bước \(currentStage)/\(totalStages)"
    guard let detail, !detail.isEmpty else { return base }
    return "\(base) · \(detail)"
  }

  var body: some View {
    VStack(spacing: 14) {
      HStack {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.Ghibli.inkDark)
            .frame(width: 48, height: 48)
            .background(Color.Ghibli.inputFill, in: .circle)
            .overlay { Circle().strokeBorder(Color.Ghibli.straw.opacity(0.6), lineWidth: 1.5) }
        }
        .buttonStyle(.ghibliPress)
        .disabled(!canGoBack)
        .opacity(canGoBack ? 1 : 0.4)
        .accessibilityLabel("Quay lại")

        Spacer()

        Text(stageLabel)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color.Ghibli.inkMuted)
          .contentTransition(.numericText())
      }

      HStack(spacing: 8) {
        ForEach(1...max(totalStages, 1), id: \.self) { index in
          Capsule()
            .fill(index <= currentStage ? Color.Ghibli.wood : Color.Ghibli.straw.opacity(0.3))
            .frame(height: 6)
        }
      }
      .accessibilityElement()
      .accessibilityLabel(stageLabel)
    }
    .animation(.easeInOut(duration: 0.3), value: currentStage)
  }
}

#Preview {
  VStack(spacing: 32) {
    OnboardingHeroProgressView(currentStage: 1, canGoBack: false)
    OnboardingHeroProgressView(currentStage: 4, detail: "Thẻ 1/8")
  }
  .padding()
  .background(Color.Ghibli.cream)
}
