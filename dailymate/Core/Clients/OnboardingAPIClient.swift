//
//  OnboardingAPIClient.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct OnboardingAPIClient: Sendable {
    public var fetchAllergyIngredients: @Sendable (_ group: AllergyGroup, _ language: String) async throws -> [AllergyItem]
    public var fetchFlashcards: @Sendable (_ draft: OnboardingDraft, _ language: String) async throws -> [Flashcard]
    public var computeTasteProfile: @Sendable (_ draft: OnboardingDraft, _ language: String) async throws -> TasteResult
}

extension OnboardingAPIClient: DependencyKey {
    public static var liveValue: Self {
        @Dependency(\.backendClient) var backend
        return Self(
            fetchAllergyIngredients: { group, language in
                let res: AllergyIngredientsResponseDTO = try await backend.request(
                    .onboardingAllergyIngredients(group: group, language: language),
                    as: AllergyIngredientsResponseDTO.self
                )
                return res.ingredients.map { AllergyItem(id: $0.id, name: $0.name, group: group) }
            },
            fetchFlashcards: { draft, language in
                let body = OnboardingMapper.toFlashcardsRequest(draft)
                let res = try await backend.request(
                    try .onboardingFlashcards(body, language: language),
                    as: FlashcardsResponseDTO.self
                )
                return res.cards.map(OnboardingMapper.toEntity)
            },
            computeTasteProfile: { draft, language in
                let body = OnboardingMapper.toTasteRequest(draft)
                let res = try await backend.request(
                    try .onboardingTasteProfile(body, language: language),
                    as: TasteProfileResponseDTO.self
                )
                return OnboardingMapper.toEntity(res)
            }
        )
    }

    public static var previewValue: Self {
        Self(
            fetchAllergyIngredients: { _, _ in [] },
            fetchFlashcards: { _, _ in [] },
            computeTasteProfile: { _, _ in
                TasteResult(
                    tasteWeight: .default,
                    source: .region,
                    likedDishIds: [],
                    dislikedDishIds: []
                )
            }
        )
    }

    public static var testValue: Self {
        Self()
    }
}

extension DependencyValues {
    public var onboardingAPIClient: OnboardingAPIClient {
        get { self[OnboardingAPIClient.self] }
        set { self[OnboardingAPIClient.self] = newValue }
    }
}
