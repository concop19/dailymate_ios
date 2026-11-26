//
//  HomeClient.swift
//  dailymate
//
//  Created by ManhLe on 11/23/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct HomeClient: Sendable {
    /// Gọi `GET /api/weather?lat=<lat>&lon=<lon>` và trả về toàn bộ chuỗi JSON (pretty-printed).
    public var fetchWeatherRawJSON: @Sendable (_ lat: Double, _ lon: Double) async throws -> WeatherResponseDTO
    public var getIngredientSuggest: @Sendable (_ searchParam: SearchParamsDTO)async throws -> SuggestIngredientsResponseDTO
}

extension HomeClient: DependencyKey {
    public static var liveValue: Self {
        @Dependency(\.backendClient) var backend
        return Self(
            fetchWeatherRawJSON: { lat, lon in
                let data = try await backend.request(.weather(lat: lat, lon: lon), as: WeatherResponseDTO.self)
                return data
            },
            getIngredientSuggest: { searchParams in
                let data = try await backend.request(
                    try .ingredientSuggest(searchParam: searchParams),
                    as: SuggestIngredientsResponseDTO.self
                )
                return data
            }
        )
    }

    public static var previewValue: Self {
        Self(
            fetchWeatherRawJSON: { _, _ in
                WeatherResponseDTO(
                    aqi: 25,
                    cacheHit: false,
                    condition: "Có mây",
                    expiresAt: nil,
                    humidity: 62,
                    pressure: 1014,
                    season: "autumn",
                    temperature: 30,
                    uvIndex: 0,
                    weatherSource: "openweather",
                    weatherVector: WeatherVectorDTO(
                        coldStressIndex: 0,
                        comfortable: 0,
                        dehydrationRisk: 0.2114,
                        heatStressIndex: 0.3062,
                        immuneLoad: 0.3063,
                        infectionRisk: 0.11,
                        oxidativeStressRisk: 0.115
                    ),
                    windSpeed: 11.1
                )
            },
            getIngredientSuggest: { _ in
                SuggestIngredientsResponseDTO(
                    sections: [
                        SuggestSectionDTO(
                            key: "protein",
                            items: [
                                SuggestedIngredientDTO(
                                    id: 102,
                                    name: "Thịt heo ba chỉ",
                                    category: "meat",
                                    preselect: true,
                                    dishCount: 42,
                                    reasons: [SuggestReasonDTO(key: "weather", label: "Hợp trời mát")]
                                )
                            ]
                        )
                    ]
                )
            }
        )
    }

    public static var testValue: Self {
        Self()
    }
}

extension DependencyValues {
    public var homeClient: HomeClient {
        get { self[HomeClient.self] }
        set { self[HomeClient.self] = newValue }
    }
}
