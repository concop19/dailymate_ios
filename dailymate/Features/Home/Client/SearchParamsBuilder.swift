//
//  SearchParamsBuilder.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import Foundation

enum SearchParamsBuilder {
    static let defaultHeightCm: Double = 160.0
    static let defaultWeightKg: Double = 55.0
    static let defaultMaxPrepTime: Int = 60
    static let defaultCostPreference: Int = 2

    static func base(
        profile: UserProfile?,
        lat: Double,
        lon: Double,
        province: String? = nil,
        dishCategory: HomeFeature.DishCategory = .all,
        cookingMethods: Set<HomeFeature.CookingMethod> = [],
        allergies: [String] = [],
        costPreference: Int = defaultCostPreference,
        cuisineScope: String = "global"
    ) -> SearchParamsDTO {
        let personal = PersonalParamsDTO(
            gender: (profile?.gender ?? .female).rawValue,
            height: defaultHeightCm,
            weight: defaultWeightKg,
            dietType: (profile?.dietType ?? .omnivore).rawValue,
            tasteWeight: profile?.tasteWeight,
            homeRegion: profile?.homeRegion?.rawValue,
            nation: profile?.nation.rawValue,
            likedDishIds: profile?.likedDishIds ?? [],
            dislikedDishIds: profile?.dislikedDishIds ?? [],
            allergies: allergies,
            maxPrepTime: defaultMaxPrepTime,
            metricsMeasured: false
        )

        let roundedLat = (lat * 100).rounded() / 100
        let roundedLon = (lon * 100).rounded() / 100
        let tools = cookingMethods.map(\.apiKey).sorted()

        return SearchParamsDTO(
            lat: roundedLat,
            lon: roundedLon,
            weather: nil,
            personal: personal,
            cuisineScope: cuisineScope,
            dishTypeFilter: dishCategory.apiKey,
            costPreference: costPreference,
            mealFilters: MealFiltersDTO(cookingTools: tools.isEmpty ? nil : tools),
            location: SearchLocationDTO(
                lat: roundedLat,
                lon: roundedLon,
                province: province?.isEmpty == false ? province : nil
            )
        )
    }

    static func withIngredients(
        base: SearchParamsDTO,
        ingredientIds: [Int],
        mode: HomeFeature.SuggestionMode
    ) -> SearchParamsDTO {
        var copy = base
        let uniqueIds = Array(Set(ingredientIds)).sorted()
        let isFridge = mode == .fromFridge

        if uniqueIds.isEmpty {
            copy.marketBasket = MarketBasketDTO(
                isSkipped: true,
                selectedIngredientIds: [],
                boostStrategy: "none"
            )
        } else {
            copy.marketBasket = MarketBasketDTO(
                isSkipped: false,
                selectedIngredientIds: uniqueIds,
                boostStrategy: isFridge ? "strict" : "soft"
            )
        }
        copy.mealFilters.mode = isFridge ? "fridge" : "suggest"
        return copy
    }
}
