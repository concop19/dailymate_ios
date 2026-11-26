import Foundation

// MARK: - RPC: get_bootstrap()

/// Kết quả `get_bootstrap()`: settings + mọi hồ sơ của user trong 1 request.
public struct BootstrapResponseDTO: Decodable, Sendable {
    public let settings: UserSettingsDataDTO?
    public let profiles: [UserProfileRowDTO]
    public let serverTime: String?

    enum CodingKeys: String, CodingKey {
        case settings, profiles
        case serverTime = "server_time"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = try container.decodeIfPresent(UserSettingsDataDTO.self, forKey: .settings)
        profiles = try container.decodeIfPresent([UserProfileRowDTO].self, forKey: .profiles) ?? []
        serverTime = try container.decodeIfPresent(String.self, forKey: .serverTime)
    }
}

// MARK: - Bảng: public.user_settings (cột `data`)

/// Chỉ khai báo các key mà luồng onboarding dùng. Key khác trong `data` bị bỏ qua khi decode
/// và không bị đụng tới khi gộp vì `merge_user_settings` chỉ gộp nông.
public struct UserSettingsDataDTO: Codable, Sendable {
    public var activeProfileId: String?

    enum CodingKeys: String, CodingKey {
        case activeProfileId = "active_profile_id"
    }
}

// MARK: - Bảng: public.user_profiles

public struct UserProfileRowDTO: Codable, Sendable {
    public let profileId: UUID
    public let sortOrder: Int?
    public let data: ProfileDataDTO
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case data
        case profileId = "profile_id"
        case sortOrder = "sort_order"
        case updatedAt = "updated_at"
    }
}

/// Dòng insert vào `user_profiles` khi tạo hồ sơ mới.
public struct UserProfileInsertDTO: Encodable, Sendable {
    public let profileId: UUID
    public let userId: UUID
    public let sortOrder: Int
    public let data: ProfileDataDTO

    enum CodingKeys: String, CodingKey {
        case data
        case profileId = "profile_id"
        case userId    = "user_id"
        case sortOrder = "sort_order"
    }
}

/// Nội dung cột `user_profiles.data`. Giữ nguyên tên key app đang dùng.
/// Trường `nil` không được encode nên khi dùng làm `p_patch` của `patch_profile`
/// thì server giữ nguyên giá trị cũ của key đó.
/// `body_metrics` cố ý không có ở đây: chỉ ghi qua RPC `add_body_metric`.
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
    public var tasteProfile: TasteVector?
    public var tasteMode: String?
    public var tasteUpdatedAt: String?
    public var likedDishIds: [String]?
    public var dislikedDishIds: [String]?
    public var allergies: [ProfileAllergyDTO]?
    public var onboardingVersion: Int?
    public var onboardingCompletedAt: String?
    public var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case displayName, relation, isDefault, gender, age, nation, allergies
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

/// Một phần tử trong `data.allergies` (thay cho 1 dòng của bảng cũ `app_allergies`).
public struct ProfileAllergyDTO: Codable, Equatable, Sendable {
    public let allergyKey: String
    public let displayName: String?
    public let addedAt: String?

    enum CodingKeys: String, CodingKey {
        case allergyKey  = "allergy_key"
        case displayName = "display_name"
        case addedAt     = "added_at"
    }
}

// MARK: - RPC params

public struct PatchProfileParams: Encodable, Sendable {
    public let profileId: UUID
    public let patch: ProfileDataDTO

    enum CodingKeys: String, CodingKey {
        case profileId = "p_profile_id"
        case patch     = "p_patch"
    }
}

/// Một lần đo gửi cho `add_body_metric` (`p_metric`).
public struct BodyMetricDTO: Codable, Sendable {
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

public struct AddBodyMetricParams: Encodable, Sendable {
    public let profileId: UUID
    public let metric: BodyMetricDTO

    enum CodingKeys: String, CodingKey {
        case profileId = "p_profile_id"
        case metric    = "p_metric"
    }
}

public struct MergeUserSettingsParams: Encodable, Sendable {
    public let patch: UserSettingsDataDTO

    enum CodingKeys: String, CodingKey {
        case patch = "p_patch"
    }
}
