//
//  CookingFinishPopup.swift
//  dailymate
//

import Lottie
import SwiftUI

/// Popup chúc mừng khi hoàn thành tất cả các bước.
struct CookingFinishPopup: View {
    let dishTitle: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14) {
                LottieView(animation: .named("Dance cat"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                Text("Hoàn thành rồi! 🎉")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Color.Ghibli.inkDark)
                Text("Bạn đã nấu xong món \"\(dishTitle)\". Chúc bạn ăn ngon miệng nha!")
                    .font(.subheadline)
                    .foregroundStyle(Color.Ghibli.inkBody)
                    .multilineTextAlignment(.center)
                GhibliPrimaryButton(title: "Xong", icon: "checkmark", color: CookingPalette.green, action: onConfirm)
                Button("Xem lại các bước", action: onDismiss)
                    .font(.subheadline)
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }
            .padding(24)
            .background(CookingPalette.cardCream, in: .rect(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28).strokeBorder(Color.Ghibli.straw.opacity(0.6), lineWidth: 1)
            }
            .shadow(color: Color.Ghibli.wood.opacity(0.3), radius: 16, y: 8)
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    CookingFinishPopup(dishTitle: "Thịt kho tiêu xanh", onConfirm: {}, onDismiss: {})
}
