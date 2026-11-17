//
//  GhibliPressButtonStyle.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Hiệu ứng nhấn: thu nhỏ + lún nhẹ + nảy spring, mờ hẳn khi bị disable.
struct GhibliPressButtonStyle: ButtonStyle {
  var pressedScale: CGFloat = 0.95
  var hoverScale: CGFloat = 1.02
  var verticalOffset: CGFloat = 2

  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? pressedScale : 1)
      .offset(y: configuration.isPressed ? verticalOffset : 0)
      .brightness(configuration.isPressed ? -0.06 : 0)
      .opacity(isEnabled ? (configuration.isPressed ? 0.88 : 1) : 0.6)
      .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
  }
}

extension ButtonStyle where Self == GhibliPressButtonStyle {
  static var ghibliPress: GhibliPressButtonStyle { GhibliPressButtonStyle() }

  static func ghibliPress(
    pressedScale: CGFloat = 0.95,
    hoverScale: CGFloat = 1.02,
    verticalOffset: CGFloat = 2
  ) -> GhibliPressButtonStyle {
    GhibliPressButtonStyle(
      pressedScale: pressedScale,
      hoverScale: hoverScale,
      verticalOffset: verticalOffset
    )
  }
}
