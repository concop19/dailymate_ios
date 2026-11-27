//
//  WeatherResponseDTO.swift
//  dailymate
//
//  Created by ManhLe on 11/23/26.
//

import Foundation

/// Response từ `GET /api/weather?lat=<lat>&lon=<lon>`.
public struct WeatherResponseDTO: Equatable, Codable, Sendable {
    public let aqi: Int?
    public let cacheHit: Bool?
    public let condition: String
    public let expiresAt: String?
    public let humidity: Double
    public let pressure: Double?
    public let season: String
    public let temperature: Double
    public let uvIndex: Double?
    public let weatherSource: String?
    public let weatherVector: WeatherVectorDTO
    public let windSpeed: Double?

    enum CodingKeys: String, CodingKey {
        case aqi, condition, humidity, pressure, season, temperature
        case cacheHit      = "cache_hit"
        case expiresAt     = "expires_at"
        case uvIndex       = "uv_index"
        case weatherSource = "weather_source"
        case weatherVector = "weather_vector"
        case windSpeed     = "wind_speed"
    }
}

public struct WeatherVectorDTO: Equatable, Codable, Sendable {
    public let coldStressIndex: Double
    public let comfortable: Double
    public let dehydrationRisk: Double
    public let heatStressIndex: Double
    public let immuneLoad: Double
    public let infectionRisk: Double
    public let oxidativeStressRisk: Double

    enum CodingKeys: String, CodingKey {
        case comfortable
        case coldStressIndex     = "cold_stress_index"
        case dehydrationRisk     = "dehydration_risk"
        case heatStressIndex     = "heat_stress_index"
        case immuneLoad          = "immune_load"
        case infectionRisk       = "infection_risk"
        case oxidativeStressRisk = "oxidative_stress_risk"
    }
}
