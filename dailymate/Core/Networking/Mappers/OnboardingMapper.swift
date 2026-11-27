//
//  OnboardingMapper.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import Foundation

public enum OnboardingMapper {
    // MARK: - Backend REST API Mapping

    public static func toFlashcardsRequest(_ draft: OnboardingDraft) -> FlashcardsRequestDTO {
        FlashcardsRequestDTO(
            nation: draft.nation == .vietnam ? "vietnam" : "global",
            homeRegion: draft.effectiveRegion.rawValue,
            dietType: draft.dietType.rawValue,
            allergies: draft.allergyKeysForRequest,
            seed: Int.random(in: 0..<1_000_000)
        )
    }

    public static func toEntity(_ dto: FlashcardDTO) -> Flashcard {
        Flashcard(
            dishId: dto.dishId,
            title: dto.title,
            imageURL: dto.imageUrl.flatMap(URL.init(string:)),
            label: dto.label,
            tasteProfile: dto.tasteProfile
        )
    }

    public static func toTasteRequest(_ draft: OnboardingDraft) -> TasteProfileRequestDTO {
        let votes = draft.cards.compactMap { card -> VoteDTO? in
            guard let vote = draft.votes[card.dishId] else { return nil }
            return VoteDTO(dishId: card.dishId, vote: vote.rawValue)
        }
        return TasteProfileRequestDTO(
            homeRegion: draft.effectiveRegion.rawValue,
            votes: votes
        )
    }

    public static func toEntity(_ dto: TasteProfileResponseDTO) -> TasteResult {
        TasteResult(
            tasteWeight: dto.tasteWeight,
            source: TasteSource(rawValue: dto.source) ?? .region,
            likedDishIds: dto.likedDishIds ?? [],
            dislikedDishIds: dto.dislikedDishIds ?? []
        )
    }

    // MARK: - Supabase DB Mapping

    /// Khoá tạm cho hồ sơ chưa tồn tại trên server (user mới chưa onboarding).
    /// Chỉ dùng làm khoá lưu bản nháp cục bộ, không bao giờ gửi lên Supabase.
    public static let defaultProfileId = "default"

    public static func defaultStartupProfile(
        profileId: String = OnboardingMapper.defaultProfileId,
        displayName: String = "Bạn"
    ) -> UserProfile {
        UserProfile(
            profileId: profileId,
            displayName: displayName,
            gender: nil,
            birthYear: nil,
            age: nil,
            nation: .vietnam,
            homeRegion: nil,
            dietType: .omnivore,
            tasteWeight: nil,
            likedDishIds: [],
            dislikedDishIds: [],
            onboardingVersion: nil,
            onboardingCompletedAt: nil,
            isPersisted: false
        )
    }

    /// Chọn hồ sơ khởi động từ kết quả `get_bootstrap()`:
    /// ưu tiên `settings.active_profile_id`, sau đó là hồ sơ có `sort_order` nhỏ nhất.
    public static func selectStartupRow(_ bootstrap: BootstrapResponseDTO) -> UserProfileRowDTO? {
        if let activeId = bootstrap.settings?.activeProfileId.flatMap(UUID.init(uuidString:)),
           let active = bootstrap.profiles.first(where: { $0.profileId == activeId }) {
            return active
        }
        return bootstrap.profiles.min { ($0.sortOrder ?? .max) < ($1.sortOrder ?? .max) }
    }

    public static func toEntity(_ dto: UserProfileRowDTO) -> UserProfile {
        let data = dto.data
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        let computedAge = data.age ?? data.birthYear.map { max(1, currentYear - $0) }

        return UserProfile(
            profileId: dto.profileId.uuidString.lowercased(),
            displayName: data.displayName ?? "Bạn",
            gender: data.gender.flatMap(Gender.init(rawValue:)),
            birthYear: data.birthYear,
            age: computedAge,
            nation: data.nation.flatMap(Nation.init(rawValue:)) ?? .vietnam,
            homeRegion: data.homeRegion.flatMap(HomeRegion.init(rawValue:)),
            dietType: data.dietType.flatMap(DietType.init(rawValue:)) ?? .omnivore,
            tasteWeight: data.tasteWeight ?? data.tasteProfile,
            likedDishIds: data.likedDishIds ?? [],
            dislikedDishIds: data.dislikedDishIds ?? [],
            onboardingVersion: data.onboardingVersion,
            onboardingCompletedAt: data.onboardingCompletedAt.flatMap(parseISO8601Date),
            isPersisted: true
        )
    }

    /// Dữ liệu onboarding cho cột `user_profiles.data`.
    /// - `includeIdentity`: `true` khi tạo hồ sơ mới (ghi `displayName`, `relation`, `isDefault`).
    ///   Khi `patch_profile` một hồ sơ đã có thì để `false` để server giữ nguyên các key này.
    /// - `allergies` luôn được gửi nguyên mảng vì `patch_profile` thay toàn bộ giá trị của key.
    public static func toProfileData(
        draft: OnboardingDraft,
        includeIdentity: Bool,
        displayName: String = "Bạn",
        now: Date = Date()
    ) -> ProfileDataDTO {
        let nowISO = formatISO8601Date(now)
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: now)
        let tasteWeight = draft.tasteResult?.tasteWeight ?? .default
        let tasteSource = (draft.tasteResult?.source ?? .region).rawValue

        return ProfileDataDTO(
            displayName: includeIdentity ? displayName : nil,
            relation: includeIdentity ? "self" : nil,
            isDefault: includeIdentity ? true : nil,
            gender: draft.gender?.rawValue,
            birthYear: draft.birthYear,
            age: draft.birthYear.map { max(1, currentYear - $0) },
            nation: draft.nation.rawValue,
            homeRegion: draft.effectiveRegion.rawValue,
            dietType: draft.dietType.rawValue,
            tasteWeight: tasteWeight,
            tasteProfile: tasteWeight,
            tasteMode: tasteSource,
            tasteUpdatedAt: nowISO,
            likedDishIds: draft.tasteResult?.likedDishIds ?? [],
            dislikedDishIds: draft.tasteResult?.dislikedDishIds ?? [],
            allergies: toAllergyDTOs(draft: draft, now: now),
            onboardingVersion: 1,
            onboardingCompletedAt: nowISO,
            updatedAt: nowISO
        )
    }

    /// Số đo gửi cho `add_body_metric`. Ưu tiên số đo đã chốt ở Stage 1.
    public static func toBodyMetricDTO(draft: OnboardingDraft, now: Date = Date()) -> BodyMetricDTO {
        let metrics = draft.bodyMetrics
        return BodyMetricDTO(
            heightCm: metrics?.heightCm ?? draft.heightCm,
            weightKg: metrics?.weightKg ?? draft.weightKg,
            measuredAt: formatISO8601Date(metrics?.measuredAt ?? now),
            note: metrics?.note ?? "onboarding"
        )
    }

    public static func toAllergyDTOs(draft: OnboardingDraft, now: Date = Date()) -> [ProfileAllergyDTO] {
        guard !draft.noAllergy else { return [] }
        let nowISO = formatISO8601Date(now)

        var seenKeys = Set<String>()
        var result: [ProfileAllergyDTO] = []

        for group in draft.allergyGroups where seenKeys.insert(group.rawValue).inserted {
            result.append(
                ProfileAllergyDTO(allergyKey: group.rawValue, displayName: group.rawValue, addedAt: nowISO)
            )
        }
        for item in draft.allergyItems where seenKeys.insert(String(item.id)).inserted {
            result.append(
                ProfileAllergyDTO(allergyKey: String(item.id), displayName: item.name, addedAt: nowISO)
            )
        }
        return result
    }

    // MARK: - ISO-8601 Helpers

    public static func formatISO8601Date(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    public static func parseISO8601Date(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) {
            return date
        }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: string)
    }
}
