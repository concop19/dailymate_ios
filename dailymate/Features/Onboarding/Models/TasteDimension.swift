//
//  TasteDimension.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import Foundation

/// 7 chiều vị giác trong `TasteVector`, khớp với tên hiển thị và icon ở màn tổng kết Stage 5.
public enum TasteDimension: String, CaseIterable, Equatable, Identifiable, Sendable {
  case salty
  case umami
  case spicy
  case sweet
  case sour
  case astringent
  case bitter

  public var id: String { rawValue }

  public var displayTitle: String {
    switch self {
    case .salty:      "Đậm đà"
    case .umami:      "Ngọt thịt"
    case .spicy:      "Cay"
    case .sweet:      "Ngọt dịu"
    case .sour:       "Chua thanh"
    case .astringent: "Chát"
    case .bitter:     "Đắng nhẹ"
    }
  }

  public var displayEmoji: String {
    switch self {
    case .salty:      "🧂"
    case .umami:      "🍜"
    case .spicy:      "🌶️"
    case .sweet:      "🍬"
    case .sour:       "🍋"
    case .astringent: "🍵"
    case .bitter:     "☕"
    }
  }

  public func value(in vector: TasteVector) -> Double {
    switch self {
    case .salty:      vector.salty
    case .umami:      vector.umami
    case .spicy:      vector.spicy
    case .sweet:      vector.sweet
    case .sour:       vector.sour
    case .astringent: vector.astringent
    case .bitter:     vector.bitter
    }
  }

  public func setValue(_ rawValue: Double, in vector: inout TasteVector) {
    let clamped = min(max(rawValue, 0), 1)
    switch self {
    case .salty:      vector.salty = clamped
    case .umami:      vector.umami = clamped
    case .spicy:      vector.spicy = clamped
    case .sweet:      vector.sweet = clamped
    case .sour:       vector.sour = clamped
    case .astringent: vector.astringent = clamped
    case .bitter:     vector.bitter = clamped
    }
  }

  /// Sắp xếp 7 chiều vị giác giảm dần theo giá trị trong `TasteVector` (nếu bằng nhau thì giữ thứ tự mặc định).
  public static func sortedByWeight(in vector: TasteVector) -> [TasteDimension] {
    allCases.enumerated()
      .sorted { lhs, rhs in
        let lVal = lhs.element.value(in: vector)
        let rVal = rhs.element.value(in: vector)
        if abs(lVal - rVal) > 0.0001 {
          return lVal > rVal
        }
        return lhs.offset < rhs.offset
      }
      .map(\.element)
  }

  /// Dòng tóm tắt Top 3 vị nổi bật nhất: `"Đậm đà · Ngọt thịt · Cay — mình nhớ rồi nha!"`.
  public static func topThreeHeadline(for vector: TasteVector) -> String {
    let top3 = sortedByWeight(in: vector)
      .prefix(3)
      .map(\.displayTitle)
      .joined(separator: " · ")
    return "\(top3) — mình nhớ rồi nha!"
  }
}
