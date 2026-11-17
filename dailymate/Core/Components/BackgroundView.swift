//
//  BackgroundView.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Nền toàn màn hình phong cách Ghibli, cho phép truyền `Image` (hoặc `GhibliTexture`) tuỳ ý.
struct BackgroundView: View {
  var image: Image
  var baseColor: Color
  var overlayColor: Color
  var imageOpacity: Double

  init(
    image: Image = GhibliTexture.wood.image,
    baseColor: Color = Color.Ghibli.wood,
    overlayColor: Color = Color.Ghibli.creamOverlay,
    imageOpacity: Double = 0.82
  ) {
    self.image = image
    self.baseColor = baseColor
    self.overlayColor = overlayColor
    self.imageOpacity = imageOpacity
  }

  init(
    texture: GhibliTexture,
    baseColor: Color = Color.Ghibli.wood,
    overlayColor: Color = Color.Ghibli.creamOverlay,
    imageOpacity: Double = 0.82
  ) {
    self.init(
      image: texture.image,
      baseColor: baseColor,
      overlayColor: overlayColor,
      imageOpacity: imageOpacity
    )
  }

  var body: some View {
    baseColor
      .overlay {
        image
          .resizable()
          .scaledToFill()
          .opacity(imageOpacity)
      }
      .overlay { overlayColor }
      .clipped()
      .ignoresSafeArea()
  }
}

#Preview("Mặc định (Gỗ)") {
  BackgroundView()
}

#Preview("Bầu trời") {
  BackgroundView(image: GhibliTexture.sky.image, overlayColor: .clear, imageOpacity: 1)
}
