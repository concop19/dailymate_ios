//
//  SearchParamsDTO.swift
//  dailymate
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
