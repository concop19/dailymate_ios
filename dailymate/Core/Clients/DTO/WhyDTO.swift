//
//  WhyDTO.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import Foundation

// MARK: - Dữ liệu `why` (Tab "Vì sao hợp")

public struct WhyDTO: Equatable, Decodable, Sendable {
    public let reasons: [WhyItemDTO]
    public let tradeoffs: [WhyItemDTO]?
    public let fit: [String: Double]?
    public let share: [String: Double]?
    public let rank: WhyRankDTO?
    public let formula: WhyFormulaDTO?
}

public struct WhyItemDTO: Equatable, Decodable, Sendable {
    public let code: String
    public let facts: WhyFactsDTO?
    public let loss: Double?
}

/// Số liệu đi kèm mỗi lý do (`reasons[].facts`) hoặc điểm trừ (`tradeoffs[].facts`).
public struct WhyFactsDTO: Equatable, Decodable, Sendable {
    // Thời tiết & cơ thể
    public let temp: Double?
    public let pct: Double?
    public let ings: [String]?
    public let kcal: Double?
    public let target: Double?
    public let pts: Double?

    // Khẩu vị
    public let tastes: [WhyTasteFactDTO]?
    public let avoids: [String]?
    public let source: String?
    public let k: String?

    // Vùng miền & mùa
    public let avail: Double?
    public let province: String?
    public let region: String?
    public let origin: String?
    public let everyday: Bool?
    public let season: String?

    // Giỏ nguyên liệu
    public let have: [String]?
    public let missing: [String]?
    public let mainHave: Int?
    public let mainTotal: Int?

    // Thời gian & chi phí
    public let min: Double?
    public let limit: Double?
    public let vnd: Double?

    enum CodingKeys: String, CodingKey {
        case temp, pct, ings, kcal, target, pts
        case tastes, avoids, source, k
        case avail, province, region, origin, everyday, season
        case have, missing
        case mainHave  = "main_have"
        case mainTotal = "main_total"
        case min, limit, vnd
    }
}

public struct WhyTasteFactDTO: Equatable, Decodable, Sendable {
    public let k: String
    public let user: Double?
    public let pct: Double?
}

public struct WhyRankDTO: Equatable, Decodable, Sendable {
    public let pos: Int?
    public let matchPct: Double?
    public let liftedForVariety: Bool?

    enum CodingKeys: String, CodingKey {
        case pos
        case matchPct         = "match_pct"
        case liftedForVariety = "lifted_for_variety"
    }
}

public struct WhyFormulaDTO: Equatable, Decodable, Sendable {
    public let terms: [WhyTermDTO]?
    public let mults: [WhyMultDTO]?
    public let score: Double
    public let base: Double?
}

public struct WhyTermDTO: Equatable, Decodable, Sendable {
    public let k: String
    public let edge: Double
}

public struct WhyMultDTO: Equatable, Decodable, Sendable {
    public let k: String
    public let x: Double
    public let edge: Double
}

// MARK: - Fallback `explanation` kiểu cũ

public struct DishLegacyExplanationDTO: Equatable, Decodable, Sendable {
    public let headline: String
    public let tags: [String]?

    private enum CodingKeys: String, CodingKey { case headline, tags }

    public init(headline: String = "", tags: [String]? = nil) {
        self.headline = headline
        self.tags = tags
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer() {
            if let str = try? single.decode(String.self) {
                self.headline = str
                self.tags = nil
                return
            }
            if let arr = try? single.decode([String].self) {
                self.headline = arr.first ?? ""
                self.tags = nil
                return
            }
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.headline = try container.decodeIfPresent(String.self, forKey: .headline) ?? ""
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags)
    }
}
