//
//  RecommendDTOs.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import Foundation

// MARK: - Request chung cho POST /api/v1/suggest-ingredients & POST /api/v1/recommend

public struct SearchParamsDTO: Equatable, Codable, Sendable {
    public var lat: Double
    public var lon: Double
    public var weather: WeatherResponseDTO?
    public var personal: PersonalParamsDTO
    public var cuisineScope: String
    public var dishTypeFilter: String
    public var costPreference: Int
    public var mealFilters: MealFiltersDTO
    public var location: SearchLocationDTO
    public var marketBasket: MarketBasketDTO?
    public var recentDishIds: [String]?
    public var page: Int?
    public var pageSize: Int?
    public var excludeIds: [Int]?

    public init(
        lat: Double,
        lon: Double,
        weather: WeatherResponseDTO? = nil,
        personal: PersonalParamsDTO,
        cuisineScope: String = "global",
        dishTypeFilter: String = "all",
        costPreference: Int = 2,
        mealFilters: MealFiltersDTO = MealFiltersDTO(),
        location: SearchLocationDTO,
        marketBasket: MarketBasketDTO? = nil,
        recentDishIds: [String]? = nil,
        page: Int? = nil,
        pageSize: Int? = nil,
        excludeIds: [Int]? = nil
    ) {
        self.lat = lat
        self.lon = lon
        self.weather = weather
        self.personal = personal
        self.cuisineScope = cuisineScope
        self.dishTypeFilter = dishTypeFilter
        self.costPreference = costPreference
        self.mealFilters = mealFilters
        self.location = location
        self.marketBasket = marketBasket
        self.recentDishIds = recentDishIds
        self.page = page
        self.pageSize = pageSize
        self.excludeIds = excludeIds
    }

    enum CodingKeys: String, CodingKey {
        case lat, lon, weather, personal, location, page
        case cuisineScope   = "cuisine_scope"
        case dishTypeFilter = "dish_type_filter"
        case costPreference = "cost_preference"
        case mealFilters    = "meal_filters"
        case marketBasket   = "market_basket"
        case recentDishIds  = "recent_dish_ids"
        case pageSize       = "page_size"
        case excludeIds     = "exclude_ids"
    }
}

public struct PersonalParamsDTO: Equatable, Codable, Sendable {
    public var gender: String
    public var height: Double
    public var weight: Double
    public var dietType: String
    public var tasteWeight: TasteVector?
    public var homeRegion: String?
    public var nation: String?
    public var likedDishIds: [String]
    public var dislikedDishIds: [String]
    public var allergies: [String]
    public var maxPrepTime: Int
    /// `true` khi `height`/`weight` là số đo thật của hồ sơ (`false` = mặc định 160 cm / 55 kg).
    public var metricsMeasured: Bool?

    public init(
        gender: String,
        height: Double = 160.0,
        weight: Double = 55.0,
        dietType: String = "omnivore",
        tasteWeight: TasteVector? = nil,
        homeRegion: String? = nil,
        nation: String? = nil,
        likedDishIds: [String] = [],
        dislikedDishIds: [String] = [],
        allergies: [String] = [],
        maxPrepTime: Int = 60,
        metricsMeasured: Bool? = nil
    ) {
        self.gender = gender
        self.height = height
        self.weight = weight
        self.dietType = dietType
        self.tasteWeight = tasteWeight
        self.homeRegion = homeRegion
        self.nation = nation
        self.likedDishIds = likedDishIds
        self.dislikedDishIds = dislikedDishIds
        self.allergies = allergies
        self.maxPrepTime = maxPrepTime
        self.metricsMeasured = metricsMeasured
    }

    enum CodingKeys: String, CodingKey {
        case gender, height, weight, nation, allergies
        case dietType        = "diet_type"
        case tasteWeight     = "taste_weight"
        case homeRegion      = "home_region"
        case likedDishIds    = "liked_dish_ids"
        case dislikedDishIds = "disliked_dish_ids"
        case maxPrepTime     = "max_prep_time"
        case metricsMeasured = "metrics_measured"
    }
}

public struct MealFiltersDTO: Equatable, Codable, Sendable {
    public var cookingTools: [String]?
    /// `"suggest"` | `"fridge"`
    public var mode: String?
    public var costLevel: Int?
    public var costTolerance: Int?
    public var maxCookTime: Int?

    public init(
        cookingTools: [String]? = nil,
        mode: String? = nil,
        costLevel: Int? = nil,
        costTolerance: Int? = nil,
        maxCookTime: Int? = nil
    ) {
        self.cookingTools = cookingTools
        self.mode = mode
        self.costLevel = costLevel
        self.costTolerance = costTolerance
        self.maxCookTime = maxCookTime
    }

    enum CodingKeys: String, CodingKey {
        case mode
        case cookingTools  = "cooking_tools"
        case costLevel     = "cost_level"
        case costTolerance = "cost_tolerance"
        case maxCookTime   = "max_cook_time"
    }
}

public struct SearchLocationDTO: Equatable, Codable, Sendable {
    public var lat: Double
    public var lon: Double
    public var province: String?

    public init(lat: Double, lon: Double, province: String? = nil) {
        self.lat = lat
        self.lon = lon
        self.province = province
    }
}

public struct MarketBasketDTO: Equatable, Codable, Sendable {
    /// Bắt buộc luôn gửi (`false` khi có nguyên liệu, `true` khi bỏ qua giỏ).
    public var isSkipped: Bool
    public var selectedIngredientIds: [Int]
    /// `"strict"` (tủ lạnh) | `"soft"` (gợi ý) | `"none"`
    public var boostStrategy: String

    public init(
        isSkipped: Bool,
        selectedIngredientIds: [Int] = [],
        boostStrategy: String = "none"
    ) {
        self.isSkipped = isSkipped
        self.selectedIngredientIds = selectedIngredientIds
        self.boostStrategy = boostStrategy
    }

    enum CodingKeys: String, CodingKey {
        case isSkipped             = "is_skipped"
        case selectedIngredientIds = "selected_ingredient_ids"
        case boostStrategy         = "boost_strategy"
    }
}

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
