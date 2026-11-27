//
//  SuggestIngredientsDTOs.swift
//  dailymate
//

import Foundation

// MARK: - Response cho POST /api/v1/suggest-ingredients

public struct SuggestIngredientsResponseDTO: Equatable, Decodable, Sendable {
    public let sections: [SuggestSectionDTO]

    public init(sections: [SuggestSectionDTO] = []) {
        self.sections = sections
    }

    enum CodingKeys: String, CodingKey {
        case sections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sections = try container.decodeIfPresent([SuggestSectionDTO].self, forKey: .sections) ?? []
    }
}

public struct SuggestSectionDTO: Equatable, Decodable, Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let items: [SuggestedIngredientDTO]
    /// `"allergy"` | `"diet"` | … khi nhóm bị lọc rỗng.
    public let emptyReason: String?
    public let excluded: [String: Int]

    public init(
        key: String,
        items: [SuggestedIngredientDTO] = [],
        emptyReason: String? = nil,
        excluded: [String: Int] = [:]
    ) {
        self.key = key
        self.items = items
        self.emptyReason = emptyReason
        self.excluded = excluded
    }

    enum CodingKeys: String, CodingKey {
        case key, items, excluded
        case emptyReason = "empty_reason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.items = try container.decodeIfPresent([SuggestedIngredientDTO].self, forKey: .items) ?? []
        self.emptyReason = try container.decodeIfPresent(String.self, forKey: .emptyReason)
        self.excluded = try container.decodeIfPresent([String: Int].self, forKey: .excluded) ?? [:]
    }
}

public struct SuggestedIngredientDTO: Equatable, Decodable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let category: String?
    public let preselect: Bool
    public let dishCount: Int
    public let reasons: [SuggestReasonDTO]

    public var iconURL: URL? {
        URL(string: "https://raw.githubusercontent.com/concop19/daily-mate-assets/main/ingredients/thumb/ingredient_\(id).webp")
    }

    public init(
        id: Int,
        name: String = "",
        category: String? = nil,
        preselect: Bool = false,
        dishCount: Int = 0,
        reasons: [SuggestReasonDTO] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.preselect = preselect
        self.dishCount = dishCount
        self.reasons = reasons
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, preselect, reasons
        case dishCount = "dish_count"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.preselect = try container.decodeIfPresent(Bool.self, forKey: .preselect) ?? false
        self.dishCount = try container.decodeIfPresent(Int.self, forKey: .dishCount) ?? 0
        self.reasons = try container.decodeIfPresent([SuggestReasonDTO].self, forKey: .reasons) ?? []
    }
}

public struct SuggestReasonDTO: Equatable, Decodable, Sendable {
    public let key: String
    public let label: String

    public init(key: String = "", label: String = "") {
        self.key = key
        self.label = label
    }

    enum CodingKeys: String, CodingKey {
        case key, label
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decodeIfPresent(String.self, forKey: .key) ?? ""
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
    }
}
