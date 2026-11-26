//
//  AllergyItem.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//


import Foundation

public struct AllergyItem: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let group: AllergyGroup?

    public var imageUrl : URL? {
        return URL(string: "https://raw.githubusercontent.com/concop19/daily-mate-assets/main/ingredients/icon/ingredient_\(id).webp")
    }
}

public struct BodyMetrics: Codable, Equatable, Sendable {
    public let heightCm: Double
    public let weightKg: Double
    public let measuredAt: Date
    public let note: String?
}

public struct Flashcard: Codable, Equatable, Identifiable, Sendable {
    public var id: String { dishId }
    public let dishId: String
    public let title: String
    public let imageURL: URL?
    public let label: String?
    public let tasteProfile: TasteVector
}

public struct TasteResult: Codable, Equatable, Sendable {
    public let tasteWeight: TasteVector
    public let source: TasteSource
    public let likedDishIds: [String]
    public let dislikedDishIds: [String]
}

public struct UserProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String { profileId }
    /// UUID (chuỗi thường) của dòng `user_profiles`, hoặc `OnboardingMapper.defaultProfileId`
    /// khi hồ sơ chưa tồn tại trên server.
    public var profileId: String
    public var displayName: String
    public var gender: Gender?
    public var birthYear: Int?
    public var age: Int?
    public var nation: Nation
    public var homeRegion: HomeRegion?
    public var dietType: DietType
    public var tasteWeight: TasteVector?
    public var likedDishIds: [String]
    public var dislikedDishIds: [String]
    public var onboardingVersion: Int?
    public var onboardingCompletedAt: Date?
    /// `true` khi hồ sơ đã có dòng trong `user_profiles`.
    public var isPersisted: Bool = true

    public var needsOnboarding: Bool { onboardingCompletedAt == nil }
}
