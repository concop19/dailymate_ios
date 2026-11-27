//
//  CookingStepDots.swift
//  dailymate
//

import SwiftUI

/// Chỉ báo tiến độ ở thanh dưới chế độ từng bước.
/// Tối đa `maxDots` chấm (chạm để nhảy tới bước); nhiều bước hơn thì hiện "Bước n / tổng".
struct CookingStepDots: View {
    static let maxDots = 10

    let steps: [CookingStepDTO]
    let currentIndex: Int
    let doneStepNos: Set<Int>
    let onSelect: (Int) -> Void

    var body: some View {
        if steps.count <= Self.maxDots {
            HStack(spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    let isCurrent = index == currentIndex
                    let isDone = doneStepNos.contains(step.stepNo)
                    Circle()
                        .fill(isCurrent ? CookingPalette.terracotta : isDone ? CookingPalette.terracotta.opacity(0.45) : CookingPalette.dotIdle)
                        .frame(width: isCurrent ? 14 : 11, height: isCurrent ? 14 : 11)
                        .contentShape(Rectangle().inset(by: -6))
                        .onTapGesture { onSelect(index) }
                }
            }
            .animation(.snappy, value: currentIndex)
        } else {
            Text("Bước \(currentIndex + 1) / \(steps.count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.Ghibli.inkLabel)
        }
    }
}
