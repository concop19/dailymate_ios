//
//  BMISummaryBadgeView.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Phân loại BMI (ngưỡng châu Á).
enum BMICategory: Equatable, Sendable {
  case underweight, normal, overweight, obese

  init(bmi: Double) {
    switch bmi {
    case ..<18.5: self = .underweight
    case ..<23: self = .normal
    case ..<25: self = .overweight
    default: self = .obese
    }
  }

  var title: String {
    switch self {
    case .underweight: "Hơi gầy"
    case .normal: "Cân đối"
    case .overweight: "Hơi đầy đặn"
    case .obese: "Thừa cân"
    }
  }

  static func bmi(heightCm: Double, weightKg: Double) -> Double {
    let meters = heightCm / 100
    guard meters > 0 else { return 0 }
    return weightKg / (meters * meters)
  }
}

/// Hàng hiển thị "BMI 15.6 · Hơi gầy" kèm chú thích.
struct BMISummaryBadgeView: View {
  let heightCm: Double
  let weightKg: Double

  private var bmi: Double { BMICategory.bmi(heightCm: heightCm, weightKg: weightKg) }

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      Text("BMI \(String(format: "%.1f", bmi)) · \(BMICategory(bmi: bmi).title)")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(Color.Ghibli.inkBody)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.Ghibli.straw.opacity(0.18), in: .capsule)
        .fixedSize()
        .contentTransition(.numericText())

      Text("Chỉ dùng để gợi ý món giàu năng lượng hay thanh nhẹ hơn — bạn đổi lại được trong Hồ sơ.")
        .font(.footnote)
        .foregroundStyle(Color.Ghibli.inkMuted)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .animation(.snappy(duration: 0.15), value: bmi)
  }
}

#Preview {
  BMISummaryBadgeView(heightCm: 151, weightKg: 35.5)
    .padding()
    .background(Color.Ghibli.cream)
}
