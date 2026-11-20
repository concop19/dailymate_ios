//
//  OnboardingDraft.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//


import Foundation

public struct OnboardingDraft: Codable, Equatable, Sendable {
    public var step: Int = 0
    public var gender: Gender? = nil
    public var birthYear: Int? = nil
    public var heightCm: Double = 165
    public var weightKg: Double = 55
    /// Chỉ số cơ thể chốt lại khi hoàn tất Stage 1 (đồng bộ với `heightCm` / `weightKg`).
    public var bodyMetrics: BodyMetrics? = nil
    public var nation: Nation = .vietnam
    public var homeRegion: HomeRegion? = nil
    public var dietType: DietType = .omnivore
    public var allergyGroups: [AllergyGroup] = []
    public var allergyItems: [AllergyItem] = []
    public var noAllergy: Bool = false
    public var cards: [Flashcard] = []
    public var votes: [String: SwipeVote] = [:]   // [dishId: vote]
    public var tasteResult: TasteResult? = nil

    public var effectiveRegion: HomeRegion {
        nation == .vietnam ? (homeRegion ?? .national) : .national
    }

    public var allergyKeysForRequest: [String] {
        guard !noAllergy else { return [] }
        return allergyGroups.map(\.rawValue) + allergyItems.map { String($0.id) }
    }
}