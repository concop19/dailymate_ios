//
//  ShakeEffect.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Hiệu ứng lắc ngang. Tăng `animatableData` thêm 1 (trong animation) → lắc 1 lần.
nonisolated struct ShakeEffect: GeometryEffect {
  var amplitude: CGFloat = 8
  var shakesPerUnit: CGFloat = 3
  var animatableData: CGFloat

  func effectValue(size: CGSize) -> ProjectionTransform {
    let offset = amplitude * sin(animatableData * .pi * shakesPerUnit)
    return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
  }
}

extension View {
  /// Lắc view mỗi khi `trigger` thay đổi.
  func shake(trigger: Int, amplitude: CGFloat = 8) -> some View {
    modifier(ShakeEffect(amplitude: amplitude, animatableData: CGFloat(trigger)))
      .animation(.linear(duration: 0.35), value: trigger)
  }
}
