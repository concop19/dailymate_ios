//
//  PaperCard.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI

/// Thẻ giấy kem có texture, viền vàng rơm và bóng nâu ấm.
struct PaperCard<Content: View>: View {
  var cornerRadius: CGFloat = 24
  var padding: CGFloat = 24
  @ViewBuilder var content: Content

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  }

  var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity)
      .background {
        Color.Ghibli.cream
          .overlay {
            GhibliTexture.paper.image
              .resizable()
              .scaledToFill()
          }
          .clipShape(shape)
      }
      .overlay { shape.strokeBorder(Color.Ghibli.straw, lineWidth: 1.5) }
      .shadow(color: Color.Ghibli.wood.opacity(0.22), radius: 12, x: 0, y: 6)
  }
}

#Preview {
  PaperCard {
    Text("Nội dung thẻ").frame(height: 200)
  }
  .padding()
  .background(BackgroundView())
}
