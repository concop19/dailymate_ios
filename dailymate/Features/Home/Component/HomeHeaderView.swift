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
            Button {}
            label : {
                Text("history")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    
                    .padding(.vertical, 16)
                    .background(Color.Ghibli.wood, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.Ghibli.skyDeep.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: Color.Ghibli.skyDeep.opacity(0.28), radius: 8, y: 4)
            }
            
        }
    }
}

#Preview {
    HomeHeaderView(
        coordinatesText: "16.0600, 108.2100",
        dateText: "Thứ Hai, 23/11",
       
    )
    .padding()
    .background(Color.Ghibli.cream)
}
