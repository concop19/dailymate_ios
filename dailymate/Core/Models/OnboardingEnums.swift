//
//  Gender.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//


import Foundation

public enum Gender: String, Codable, Sendable, CaseIterable {
    case male, female
}

public enum Nation: String, Codable, Sendable, CaseIterable {
    case vietnam, other
}

public enum HomeRegion: String, Codable, Sendable, CaseIterable {
    case northern, central, southern, national
}

public enum DietType: String, Codable, Sendable, CaseIterable {
    case omnivore, vegetarian, vegan
}


public enum AllergyGroup: String, Codable, Sendable, CaseIterable, Hashable {
    case seafood
    case fish
    case beef
    case pork
    case legumeNut = "legume_nut"
    case dairyEgg  = "dairy_egg"
    case poultry
    case vegetable
    case gluten
}
/*export const ALLERGY_OPTIONS = [
 { key: 'seafood',    emoji: '🦐' },
 { key: 'fish',       emoji: '🐟' },
 { key: 'beef',       emoji: '🐄' },
 { key: 'pork',       emoji: '🐖' },
 { key: 'poultry',    emoji: '🐔' },
 { key: 'legume_nut', emoji: '🥜' },
 { key: 'dairy_egg',  emoji: '🥚' },
 { key: 'vegetable',  emoji: '🥬' },
 { key: 'gluten',     emoji: '🌾' },
]*/

public enum SwipeVote: String, Codable, Sendable {
    case like, neutral, dislike
}

public enum TasteSource: String, Codable, Sendable {
    case flashcards, region
}
