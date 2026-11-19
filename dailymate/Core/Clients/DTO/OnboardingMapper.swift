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

    public static func defaultStartupProfile(
        profileId: String = "self",
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
            onboardingCompletedAt: nil
        )
    }

    public static func toEntity(_ dto: AppProfileRowDTO) -> UserProfile {
        let data = dto.data
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        let computedAge = data.age ?? data.birthYear.map { max(1, currentYear - $0) }

        return UserProfile(
            profileId: dto.profileId,
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
            onboardingCompletedAt: data.onboardingCompletedAt.flatMap(parseISO8601Date)
        )
    }

    public static func toProfileRowDTO(
        draft: OnboardingDraft,
        userId: UUID,
        profileId: String,
        existingData: ProfileDataDTO? = nil,
        defaultDisplayName: String = "Bạn",
        now: Date = Date()
    ) -> AppProfileRowDTO {
        let nowISO = formatISO8601Date(now)
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: now)
        let age = draft.birthYear.map { max(1, currentYear - $0) } ?? existingData?.age
        let resolvedTasteWeight = draft.tasteResult?.tasteWeight
            ?? existingData?.tasteWeight
            ?? existingData?.tasteProfile
            ?? .default
        let resolvedTasteSource = (draft.tasteResult?.source ?? .region).rawValue

        let profileData = ProfileDataDTO(
            displayName: existingData?.displayName ?? defaultDisplayName,
            relation: existingData?.relation ?? (profileId == "self" ? "self" : nil),
            isDefault: existingData?.isDefault ?? (profileId == "self"),
            gender: draft.gender?.rawValue ?? existingData?.gender,
            birthYear: draft.birthYear ?? existingData?.birthYear,
            age: age,
            nation: draft.nation.rawValue,
            homeRegion: draft.effectiveRegion.rawValue,
            dietType: draft.dietType.rawValue,
            tasteWeight: resolvedTasteWeight,
            tasteProfile: resolvedTasteWeight,
            tasteMode: resolvedTasteSource,
            tasteUpdatedAt: nowISO,
            likedDishIds: draft.tasteResult?.likedDishIds ?? existingData?.likedDishIds ?? [],
            dislikedDishIds: draft.tasteResult?.dislikedDishIds ?? existingData?.dislikedDishIds ?? [],
            onboardingVersion: 1,
            onboardingCompletedAt: nowISO,
            updatedAt: nowISO
        )

        return AppProfileRowDTO(
            userId: userId,
            profileId: profileId,
            data: profileData,
            updatedAt: nowISO
        )
    }

    public static func toBodyMetricsRowDTO(
        draft: OnboardingDraft,
        userId: UUID,
        profileId: String,
        now: Date = Date()
    ) -> AppBodyMetricsRowDTO {
        let nowISO = formatISO8601Date(now)
        let metricsData = BodyMetricsDataDTO(
            heightCm: draft.heightCm,
            weightKg: draft.weightKg,
            measuredAt: nowISO,
            note: "onboarding"
        )
        return AppBodyMetricsRowDTO(
            id: nil,
            userId: userId,
            profileId: profileId,
            data: metricsData,
            measuredAt: nowISO
        )
    }

    public static func toAllergyRowDTOs(
        draft: OnboardingDraft,
        userId: UUID,
        profileId: String,
        now: Date = Date()
    ) -> [AppAllergyRowDTO] {
        guard !draft.noAllergy else { return [] }
        let nowISO = formatISO8601Date(now)

        var seenKeys = Set<String>()
        var rows: [AppAllergyRowDTO] = []

        for group in draft.allergyGroups {
            let key = group.rawValue
            guard seenKeys.insert(key).inserted else { continue }
            rows.append(
                AppAllergyRowDTO(
                    userId: userId,
                    profileId: profileId,
                    allergyKey: key,
                    displayName: group.rawValue,
                    addedAt: nowISO
                )
            )
        }

        for item in draft.allergyItems {
            let key = String(item.id)
            guard seenKeys.insert(key).inserted else { continue }
            rows.append(
                AppAllergyRowDTO(
                    userId: userId,
                    profileId: profileId,
                    allergyKey: key,
                    displayName: item.name,
                    addedAt: nowISO
                )
            )
        }

        return rows
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
