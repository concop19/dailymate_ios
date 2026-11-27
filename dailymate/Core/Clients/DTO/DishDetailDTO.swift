//
//  DishDetailDTO.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import Foundation

// MARK: - Response cho GET /api/v1/dishes/{id}?lang=vi

public struct DishDetailDTO: Equatable, Decodable, Sendable {
    public let id: String
    public let title: String
    public let url: String?
    public let description: String?
    public let nation: String?
    public let imageUrl: String?
    public let cookTimeMinutes: Int?
    public let estCostVnd: Double?
    public let estCostLevel: Int?
    public let cuisineRegion: String?
    public let specialtyOrigin: String?
    public let servingSize: String?
    public let ingredients: [DishIngredientDTO]

    public var imageURL: URL? { imageUrl.flatMap(URL.init(string:)) }
    public var mainIngredients: [DishIngredientDTO] { ingredients.filter(\.isMainIngredient) }
    public var sideIngredients: [DishIngredientDTO] { ingredients.filter { !$0.isMainIngredient } }

    enum CodingKeys: String, CodingKey {
        case id, title, url, description, nation, ingredients
        case imageUrl        = "image_url"
        case cookTimeMinutes = "cook_time_minutes"
        case estCostVnd      = "est_cost_vnd"
        case estCostLevel    = "est_cost_level"
        case cuisineRegion   = "cuisine_region"
        case specialtyOrigin = "specialty_origin"
        case servingSize     = "serving_size"
    }
}

// MARK: - Nguyên liệu của món

public struct DishIngredientDTO: Equatable, Decodable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let nameEn: String?
    public let category: String?
    public let quantityG: Double?
    /// `1` = nguyên liệu chính, `0` = nguyên liệu phụ / gia vị.
    public let isMain: Int

    public var isMainIngredient: Bool { isMain == 1 }

    public var iconURL: URL? {
        URL(string: "https://raw.githubusercontent.com/concop19/daily-mate-assets/main/ingredients/thumb/ingredient_\(id).webp")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case nameEn    = "name_en"
        case quantityG = "quantity_g"
        case isMain    = "is_main"
    }
}

// MARK: - Request cho POST /api/v1/feedback

public enum DishFeedbackAction: String, Equatable, Codable, Sendable {
    case eaten
    case skipped
}

public struct FeedbackRequestDTO: Equatable, Encodable, Sendable {
    public let sessionUuid: String
    public let dishId: String
    public let action: String
    public let feedbackAt: String

    public init(
        sessionUuid: String,
        dishId: String,
        action: DishFeedbackAction,
        feedbackAt: String
    ) {
        self.sessionUuid = sessionUuid
        self.dishId = dishId
        self.action = action.rawValue
        self.feedbackAt = feedbackAt
    }

    enum CodingKeys: String, CodingKey {
        case action
        case sessionUuid = "session_uuid"
        case dishId      = "dish_id"
        case feedbackAt  = "feedback_at"
    }
}
