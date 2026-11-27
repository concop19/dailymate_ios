//
//  WhyModels.swift
//  dailymate
//

import SwiftUI

/// Nhóm yếu tố chấm điểm + các model hiển thị đã được `WhyPresenter` chuyển sẵn thành chữ.
enum WhyGroup: String, CaseIterable, Identifiable {
    case weather = "weather"
    case taste = "taste"
    case placeSeason = "place_season"
    case basket = "basket"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weather:     "Thời tiết & cơ thể"
        case .taste:       "Khẩu vị"
        case .placeSeason: "Vùng miền & mùa"
        case .basket:      "Giỏ nguyên liệu"
        }
    }

    var emoji: String {
        switch self {
        case .weather:     "⛅"
        case .taste:       "🍽️"
        case .placeSeason: "🍃"
        case .basket:      "🧺"
        }
    }

    var color: Color {
        switch self {
        case .weather:     Color(hex: 0xD9822B)
        case .taste:       Color(hex: 0xC0573E)
        case .placeSeason: Color(hex: 0x4E9A68)
        case .basket:      Color(hex: 0x7C6BB0)
        }
    }
}

struct WhyReasonView: Identifiable {
    let id = UUID()
    let emoji: String
    let color: Color
    let title: String
    let chips: [String]
}

struct WhyTradeoffView: Identifiable {
    let id = UUID()
    let emoji: String
    let text: String
}

struct WhyFormulaRow: Identifiable {
    let id: String
    let emoji: String
    let color: Color
    let label: String
    let mult: String?
    var edge: Int
}

struct WhyFormulaView {
    let score: Int
    let base: Int?
    let rows: [WhyFormulaRow]
}
