import Foundation

// Bảng: public.app_profiles
public struct AppProfileRowDTO: Codable, Sendable {
    public let userId: UUID
    public let profileId: String
    public let data: ProfileDataDTO
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case data
        case userId    = "user_id"
        case profileId = "profile_id"
        case updatedAt = "updated_at"
    }
}

public struct ProfileDataDTO: Codable, Sendable {
    public var displayName: String?
    public var relation: String?
    public var isDefault: Bool?
    public var gender: String?
    public var birthYear: Int?
    public var age: Int?
    public var nation: String?
    public var homeRegion: String?
    public var dietType: String?
    public var tasteWeight: TasteVector?
    public var tasteProfile: TasteVector?      // giữ nếu cần tương thích app RN cũ dùng chung DB
    public var tasteMode: String?
    public var tasteUpdatedAt: String?
    public var likedDishIds: [String]?
    public var dislikedDishIds: [String]?
    public var onboardingVersion: Int?
    public var onboardingCompletedAt: String?
    public var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case displayName, relation, isDefault, gender, age, nation
        case birthYear             = "birth_year"
        case homeRegion            = "home_region"
        case dietType              = "diet_type"
        case tasteWeight           = "taste_weight"
        case tasteProfile          = "taste_profile"
        case tasteMode             = "taste_mode"
        case tasteUpdatedAt        = "taste_updated_at"
        case likedDishIds          = "liked_dish_ids"
        case dislikedDishIds       = "disliked_dish_ids"
        case onboardingVersion     = "onboarding_version"
        case onboardingCompletedAt = "onboarding_completed_at"
        case updatedAt             = "updated_at"
    }
}

// Bảng: public.app_allergies
public struct AppAllergyRowDTO: Codable, Sendable {
    public let userId: UUID
    public let profileId: String
    public let allergyKey: String
    public let displayName: String?
    public let addedAt: String?

    enum CodingKeys: String, CodingKey {
        case userId      = "user_id"
        case profileId   = "profile_id"
        case allergyKey  = "allergy_key"
        case displayName = "display_name"
        case addedAt     = "added_at"
    }
}

// Bảng: public.app_body_metrics
public struct AppBodyMetricsRowDTO: Codable, Sendable {
    public let id: UUID?
    public let userId: UUID
    public let profileId: String
    public let data: BodyMetricsDataDTO
    public let measuredAt: String

    enum CodingKeys: String, CodingKey {
        case id, data
        case userId     = "user_id"
        case profileId  = "profile_id"
        case measuredAt = "measured_at"
    }
}

public struct BodyMetricsDataDTO: Codable, Sendable {
    public let heightCm: Double
    public let weightKg: Double
    public let measuredAt: String
    public let note: String?

    enum CodingKeys: String, CodingKey {
        case note
        case heightCm   = "height_cm"
        case weightKg   = "weight_kg"
        case measuredAt = "measured_at"
    }
}
