//
//  AllergyIngredientsResponseDTO.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//


import Foundation


// GET /api/v1/onboarding/allergy-ingredients
public struct AllergyIngredientsResponseDTO: Decodable, Sendable {
    public let ingredients: [AllergyIngredientDTO]
}

public struct AllergyIngredientDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let category: String?
    public let dishCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case dishCount = "dish_count"
    }
}

// POST /api/v1/onboarding/flashcards
public struct FlashcardsRequestDTO: Encodable, Sendable {
    public let nation: String        // "vietnam" | "global"
    public let homeRegion: String
    public let dietType: String
    public let allergies: [String]
    public let seed: Int

    enum CodingKeys: String, CodingKey {
        case nation, allergies, seed
        case homeRegion = "home_region"
        case dietType   = "diet_type"
    }
}

public struct FlashcardsResponseDTO: Decodable, Sendable {
    public let cards: [FlashcardDTO]
}

public struct FlashcardDTO: Decodable, Sendable {
    public let dishId: String
    public let title: String
    public let imageUrl: String?
    public let label: String?
    public let tasteProfile: TasteVector

    enum CodingKeys: String, CodingKey {
        case title, label
        case dishId       = "dish_id"
        case imageUrl     = "image_url"
        case tasteProfile = "taste_profile"
    }
}

// POST /api/v1/onboarding/taste-profile
public struct TasteProfileRequestDTO: Encodable, Sendable {
    public let homeRegion: String
    public let votes: [VoteDTO]

    enum CodingKeys: String, CodingKey {
        case votes
        case homeRegion = "home_region"
    }
}

public struct VoteDTO: Encodable, Sendable {
    public let dishId: String
    public let vote: String

    enum CodingKeys: String, CodingKey {
        case vote
        case dishId = "dish_id"
    }
}

public struct TasteProfileResponseDTO: Decodable, Sendable {
    public let tasteWeight: TasteVector
    public let source: String
    public let likedDishIds: [String]?
    public let dislikedDishIds: [String]?

    enum CodingKeys: String, CodingKey {
        case source
        case tasteWeight     = "taste_weight"
        case likedDishIds    = "liked_dish_ids"
        case dislikedDishIds = "disliked_dish_ids"
    }
}
