//
//  RecommendDTOs.swift
//  dailymate
//

import Foundation

// MARK: - Response cho POST /api/v1/recommend

public struct RecommendResponseDTO: Equatable, Decodable, Sendable {
    public let rankedDishes: [RankedDishDTO]
    public let page: Int?
    public let totalPages: Int?
    public let hasNextPage: Bool
    public let totalDishes: Int?
    public let basketWarning: BasketWarningDTO?
    public let relaxedFilters: [String]

    public init(
        rankedDishes: [RankedDishDTO] = [],
        page: Int? = nil,
        totalPages: Int? = nil,
        hasNextPage: Bool = false,
        totalDishes: Int? = nil,
        basketWarning: BasketWarningDTO? = nil,
        relaxedFilters: [String] = []
    ) {
        self.rankedDishes = rankedDishes
        self.page = page
        self.totalPages = totalPages
        self.hasNextPage = hasNextPage
        self.totalDishes = totalDishes
        self.basketWarning = basketWarning
        self.relaxedFilters = relaxedFilters
    }

    enum CodingKeys: String, CodingKey {
        case page
        case rankedDishes   = "ranked_dishes"
        case totalPages     = "total_pages"
        case hasNextPage    = "has_next_page"
        case totalDishes    = "total_dishes"
        case basketWarning  = "basket_warning"
        case relaxedFilters = "relaxed_filters"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rankedDishes = try container.decodeIfPresent([RankedDishDTO].self, forKey: .rankedDishes) ?? []
        self.page = try container.decodeIfPresent(Int.self, forKey: .page)
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
        self.hasNextPage = try container.decodeIfPresent(Bool.self, forKey: .hasNextPage) ?? false
        self.totalDishes = try container.decodeIfPresent(Int.self, forKey: .totalDishes)
        self.basketWarning = try container.decodeIfPresent(BasketWarningDTO.self, forKey: .basketWarning)
        self.relaxedFilters = try container.decodeIfPresent([String].self, forKey: .relaxedFilters) ?? []
    }
}

public struct BasketWarningDTO: Equatable, Decodable, Sendable {
    public let count: Int

    public init(count: Int = 0) {
        self.count = count
    }

    enum CodingKeys: String, CodingKey {
        case count
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
    }
}

public struct RankedDishDTO: Equatable, Decodable, Identifiable, Sendable {
    public var id: String { dishId }
    public let dishId: String
    public let rank: Int?
    public let finalScore: Double?
    public let matchPct: Double?
    public let title: String
    public let imageUrl: String?
    public let url: String?
    public let nation: String?
    public let cookTimeMin: Int?
    public let estCostVnd: Double?
    public let estCostLevel: Int?
    public let why: WhyDTO?
    public let explanation: DishLegacyExplanationDTO?
    public let missingIngredients: [String]

    public var imageURL: URL? {
        imageUrl.flatMap(URL.init(string:))
    }

    /// `match_pct` (server mới) hoặc `final_score * 100` (dữ liệu cũ).
    public var resolvedMatchPct: Int {
        Int((matchPct ?? ((finalScore ?? 0.0) * 100)).rounded())
    }

    public init(
        dishId: String,
        rank: Int? = nil,
        finalScore: Double? = nil,
        matchPct: Double? = nil,
        title: String = "",
        imageUrl: String? = nil,
        url: String? = nil,
        nation: String? = nil,
        cookTimeMin: Int? = nil,
        estCostVnd: Double? = nil,
        estCostLevel: Int? = nil,
        why: WhyDTO? = nil,
        explanation: DishLegacyExplanationDTO? = nil,
        missingIngredients: [String] = []
    ) {
        self.dishId = dishId
        self.rank = rank
        self.finalScore = finalScore
        self.matchPct = matchPct
        self.title = title
        self.imageUrl = imageUrl
        self.url = url
        self.nation = nation
        self.cookTimeMin = cookTimeMin
        self.estCostVnd = estCostVnd
        self.estCostLevel = estCostLevel
        self.why = why
        self.explanation = explanation
        self.missingIngredients = missingIngredients
    }

    /// Gộp đè dữ liệu chi tiết từ `GET /api/v1/dishes/{id}` lên món đang có.
    public func merged(with detail: DishDetailDTO) -> RankedDishDTO {
        RankedDishDTO(
            dishId: dishId,
            rank: rank,
            finalScore: finalScore,
            matchPct: matchPct,
            title: detail.title.isEmpty ? title : detail.title,
            imageUrl: detail.imageUrl.flatMap { $0.isEmpty ? nil : $0 } ?? imageUrl,
            url: detail.url.flatMap { $0.isEmpty ? nil : $0 } ?? url,
            nation: detail.nation.flatMap { $0.isEmpty ? nil : $0 } ?? nation,
            cookTimeMin: detail.cookTimeMinutes ?? cookTimeMin,
            estCostVnd: detail.estCostVnd ?? estCostVnd,
            estCostLevel: detail.estCostLevel ?? estCostLevel,
            why: why,
            explanation: explanation,
            missingIngredients: missingIngredients
        )
    }

    enum CodingKeys: String, CodingKey {
        case rank, title, url, nation, why, explanation
        case dishId             = "dish_id"
        case finalScore         = "final_score"
        case matchPct           = "match_pct"
        case imageUrl           = "image_url"
        case cookTimeMin        = "cook_time_min"
        case estCostVnd         = "est_cost_vnd"
        case estCostLevel       = "est_cost_level"
        case missingIngredients = "missing_ingredients"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringId = try? container.decode(String.self, forKey: .dishId) {
            self.dishId = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .dishId) {
            self.dishId = String(intId)
        } else {
            self.dishId = ""
        }
        self.rank = try container.decodeIfPresent(Int.self, forKey: .rank)
        self.finalScore = try container.decodeIfPresent(Double.self, forKey: .finalScore)
        self.matchPct = try container.decodeIfPresent(Double.self, forKey: .matchPct)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.nation = try container.decodeIfPresent(String.self, forKey: .nation)
        self.cookTimeMin = try container.decodeIfPresent(Int.self, forKey: .cookTimeMin)
        self.estCostVnd = try container.decodeIfPresent(Double.self, forKey: .estCostVnd)
        self.estCostLevel = try container.decodeIfPresent(Int.self, forKey: .estCostLevel)
        self.why = try? container.decodeIfPresent(WhyDTO.self, forKey: .why)
        self.explanation = try? container.decodeIfPresent(DishLegacyExplanationDTO.self, forKey: .explanation)
        self.missingIngredients = (try? container.decodeIfPresent([String].self, forKey: .missingIngredients)) ?? []
    }
}
