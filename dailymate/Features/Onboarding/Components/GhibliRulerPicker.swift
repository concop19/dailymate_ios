//
//  GhibliRulerPicker.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI
import UIKit

/// Cây thước kéo ngang để chọn giá trị số (chiều cao, cân nặng...).
/// - Kim chỉ cố định ở giữa, kéo dải vạch qua trái/phải để thay đổi giá trị theo `step`.
/// - Vạch chính mỗi `majorEvery` bước (có nhãn số), vạch trung ở nửa khoảng.
struct GhibliRulerPicker: View {
  @Binding var value: Double
  let range: ClosedRange<Double>
  var step: Double = 1
  /// Số bước giữa hai vạch chính có nhãn (vd: chiều cao step 1 → 10; cân nặng step 0.5 → 10 = 5kg).
  var majorEvery: Int = 10
  var unit: String
  var fractionDigits: Int = 0
  var tickSpacing: CGFloat = 10

  @State private var dragStartValue: Double?

  var body: some View {
    VStack(spacing: 14) {
      valueLabel
      ruler
    }
  }

  // MARK: - Value label

  private var valueLabel: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text(formatted(value))
        .font(.system(size: 52, weight: .bold, design: .serif))
        .foregroundStyle(Color.Ghibli.wood)
        .contentTransition(.numericText(value: value))
        .monospacedDigit()
      Text(unit)
        .font(.system(.title3, design: .rounded, weight: .bold))
        .foregroundStyle(Color.Ghibli.wood)
    }
    .animation(.snappy(duration: 0.15), value: value)
    .accessibilityElement(children: .combine)
  }

  // MARK: - Ruler

  private var ruler: some View {
    let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

    return Canvas { context, size in
      drawTicks(in: &context, size: size)
    }
    .frame(height: 80)
    .overlay {
      // Kim chỉ cố định ở giữa
      Capsule()
        .fill(Color.Ghibli.wood)
        .frame(width: 3, height: 52)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 8)
        .allowsHitTesting(false)
    }
    .background(Color(hex: 0xFFF9EE), in: shape)
    .overlay { shape.strokeBorder(Color.Ghibli.straw.opacity(0.4), lineWidth: 1.5) }
    .clipShape(shape)
    .contentShape(shape)
    .gesture(dragGesture)
    .accessibilityElement()
    .accessibilityLabel("\(formatted(value)) \(unit)")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: update(to: value + step)
      case .decrement: update(to: value - step)
      @unknown default: break
      }
    }
  }

  private func drawTicks(in context: inout GraphicsContext, size: CGSize) {
    let centerX = size.width / 2
    let currentIndex = value / step
    let halfVisible = Int(size.width / tickSpacing / 2) + 2
    let baseIndex = Int(currentIndex.rounded())
    let lowerIndex = Int((range.lowerBound / step).rounded(.up))
    let upperIndex = Int((range.upperBound / step).rounded(.down))
    let midEvery = majorEvery.isMultiple(of: 2) ? majorEvery / 2 : 0
    let tickColor = Color.Ghibli.inkMuted

    let start = max(lowerIndex, baseIndex - halfVisible)
    let end = min(upperIndex, baseIndex + halfVisible)
    guard start <= end else { return }

    for index in start...end {
      let x = centerX + CGFloat(Double(index) - currentIndex) * tickSpacing
      let isMajor = index.isMultiple(of: majorEvery)
      let isMid = !isMajor && midEvery > 0 && index.isMultiple(of: midEvery)

      let height: CGFloat = isMajor ? 40 : (isMid ? 30 : 22)
      let width: CGFloat = isMajor ? 2.5 : 2
      let opacity: Double = isMajor ? 1 : 0.55

      var path = Path()
      path.move(to: CGPoint(x: x, y: 12))
      path.addLine(to: CGPoint(x: x, y: 12 + height))
      context.stroke(
        path,
        with: .color(tickColor.opacity(opacity)),
        style: StrokeStyle(lineWidth: width, lineCap: .round)
      )

      if isMajor {
        let label = Text(formatted(Double(index) * step, fractionDigits: 0))
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(Color.Ghibli.inkLabel)
        context.draw(label, at: CGPoint(x: x, y: size.height - 14), anchor: .center)
      }
    }
  }

  // MARK: - Gesture

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { gesture in
        let start = dragStartValue ?? value
        if dragStartValue == nil { dragStartValue = start }
        let delta = -Double(gesture.translation.width / tickSpacing) * step
        update(to: start + delta)
      }
      .onEnded { _ in
        dragStartValue = nil
      }
  }

  private func update(to raw: Double) {
    let snapped = (raw / step).rounded() * step
    let clamped = min(max(snapped, range.lowerBound), range.upperBound)
    guard abs(clamped - value) > step / 4 else { return }
    UISelectionFeedbackGenerator().selectionChanged()
    value = clamped
  }

  // MARK: - Formatting

  private func formatted(_ number: Double, fractionDigits digits: Int? = nil) -> String {
    let digits = digits ?? fractionDigits
    return String(format: "%.\(digits)f", number)
  }
}

#Preview {
  @Previewable @State var height: Double = 151
  @Previewable @State var weight: Double = 35.5

  VStack(spacing: 32) {
    GhibliRulerPicker(value: $height, range: 100...220, step: 1, majorEvery: 10, unit: "cm")
    GhibliRulerPicker(value: $weight, range: 15...150, step: 0.5, majorEvery: 10, unit: "kg", fractionDigits: 1)
  }
  .padding()
  .background(Color.Ghibli.cream)
}
