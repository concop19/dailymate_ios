//
//  HomeModels.swift
//  dailymate
//

import Foundation

/// Các kiểu dữ liệu của Home: chế độ gợi ý, loại món, cách nấu, mức độ chỉ số thời tiết.
extension HomeFeature {
    enum SuggestionMode: String, CaseIterable, Identifiable, Equatable, Sendable {
        case recommended
        case fromFridge
        

        var id: String { rawValue }

        var title: String {
            switch self {
            case .recommended: "Gợi ý tùy chọn."
            case .fromFridge:  "Từ tủ lạnh"
           
            }
        }

        var emoji: String {
            switch self {
            case .recommended: "icon_home_suggest"
            case .fromFridge:  "icon_home_fridge"
           
            }
        }
    }

    enum DishCategory: String, CaseIterable, Identifiable, Equatable, Sendable {
        case all
        case soup
        case savory

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:    "Tất cả"
            case .soup:   "Canh"
            case .savory: "Món mặn"
            }
        }

        var emoji: String {
            switch self {
            case .all:    "🍽️"
            case .soup:   "🥣"
            case .savory: "🍖"
            }
        }

        var apiKey: String {
            switch self {
            case .all:    "all"
            case .soup:   "soup"
            case .savory: "main_dish"
            }
        }
    }

    enum CookingMethod: String, CaseIterable, Identifiable, Equatable, Sendable {
        case riceCooker
        case pan
        case airFryer
        case stirFry
        case braise
        case steam
        case boil

        var id: String { rawValue }

        var title: String {
            switch self {
            case .riceCooker: "Nồi cơm"
            case .pan:        "Chảo"
            case .airFryer:   "chiên "
            case .stirFry:    "Xào"
            case .braise:     "Kho"
            case .steam:      "Hấp"
            case .boil:       "Luộc"
            }
        }

        var emoji: String {
            switch self {
            case .riceCooker: "🍚"
            case .pan:        "🍳"
            case .airFryer:   "🔥"
            case .stirFry:    "🥘"
            case .braise:     "🍲"
            case .steam:      "♨️"
            case .boil:       "🫕"
            }
        }

        var apiKey: String {
            switch self {
            case .riceCooker: "rice_cooker"
            case .pan:        "pan"
            case .airFryer:   "air_fryer"
            case .stirFry:    "stir_fry"
            case .braise:     "braise"
            case .steam:      "steam"
            case .boil:       "boil"
            }
        }
    }

    enum MetricSeverity: Equatable, Sendable {
        case good
        case moderate
        case high
        case veryHigh
    }
}
