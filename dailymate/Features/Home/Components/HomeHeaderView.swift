//
//  HomeHeaderView.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import SwiftUI

struct HomeHeaderView: View {
    let coordinatesText: String
    let dateText: String
    let profileName: String
    let onEditProfile: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Label {
                    Text(coordinatesText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkDark)
                        .monospacedDigit()
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.Ghibli.wood)
                }

                Text(dateText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.Ghibli.inkMuted)
            }

            Spacer(minLength: 8)

            Button(action: onEditProfile) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.Ghibli.wood)

                    Text(profileName)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.Ghibli.inkDark)
                        .lineLimit(1)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.Ghibli.inkMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(hex: 0xFAF6EE).opacity(0.95), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.Ghibli.straw.opacity(0.85), lineWidth: 1.2)
                }
                .shadow(color: Color.Ghibli.wood.opacity(0.14), radius: 6, y: 3)
            }
            .buttonStyle(.ghibliPress)
            .accessibilityLabel("Tinh chỉnh hồ sơ \(profileName)")
        }
    }
}

#Preview {
    HomeHeaderView(
        coordinatesText: "16.0600, 108.2100",
        dateText: "Thứ Hai, 23/11",
        profileName: "Bản thân",
        onEditProfile: {}
    )
    .padding()
    .background(Color.Ghibli.cream)
}
