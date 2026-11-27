//
//  FlowLayout.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import SwiftUI

/// Layout tự động xếp các chip theo hàng ngang và xuống dòng khi tràn chiều rộng.
struct FlowLayout: Layout {
  var horizontalSpacing: CGFloat = 10
  var verticalSpacing: CGFloat = 10

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

    var totalHeight: CGFloat = 0
    var widestRow: CGFloat = 0

    for (index, row) in rows.enumerated() {
      widestRow = max(widestRow, row.width)
      totalHeight += row.height
      if index < rows.count - 1 {
        totalHeight += verticalSpacing
      }
    }

    return CGSize(
      width: proposal.width ?? widestRow,
      height: totalHeight
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
    var currentY = bounds.minY

    for row in rows {
      var currentX = bounds.minX
      for item in row.items {
        let yOffset = (row.height - item.size.height) / 2
        item.subview.place(
          at: CGPoint(x: currentX, y: currentY + yOffset),
          proposal: ProposedViewSize(item.size)
        )
        currentX += item.size.width + horizontalSpacing
      }
      currentY += row.height + verticalSpacing
    }
  }

  // MARK: - Row calculation

  private struct RowItem {
    let subview: LayoutSubview
    let size: CGSize
  }

  private struct Row {
    var items: [RowItem] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
    var rows: [Row] = []
    var currentRow = Row()

    for subview in subviews {
      let itemSize = subview.sizeThatFits(.unspecified)
      let spacing = currentRow.items.isEmpty ? 0 : horizontalSpacing

      if !currentRow.items.isEmpty && currentRow.width + spacing + itemSize.width > maxWidth {
        rows.append(currentRow)
        currentRow = Row()
      }

      let effectiveSpacing = currentRow.items.isEmpty ? 0 : horizontalSpacing
      currentRow.items.append(RowItem(subview: subview, size: itemSize))
      currentRow.width += effectiveSpacing + itemSize.width
      currentRow.height = max(currentRow.height, itemSize.height)
    }

    if !currentRow.items.isEmpty {
      rows.append(currentRow)
    }

    return rows
  }
}
