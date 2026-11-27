//
//  CookingStepsDTO.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import Foundation

// MARK: - Response cho GET /api/v1/dishes/{id}/cooking-steps?lang=vi

public struct CookingStepsDTO: Equatable, Decodable, Sendable {
    public var dishId: String?
    public var title: String?
    public var cookTimeMinutes: Int?
    public var cookingMethodId: String?
    public var totalSteps: Int?
    public var steps: [CookingStepDTO]
    public var language: String?

    public init(
        dishId: String? = nil,
        title: String? = nil,
        cookTimeMinutes: Int? = nil,
        cookingMethodId: String? = nil,
        totalSteps: Int? = nil,
        steps: [CookingStepDTO] = [],
        language: String? = nil
    ) {
        self.dishId = dishId
        self.title = title
        self.cookTimeMinutes = cookTimeMinutes
        self.cookingMethodId = cookingMethodId
        self.totalSteps = totalSteps
        self.steps = steps
        self.language = language
    }

    enum CodingKeys: String, CodingKey {
        case title, steps, language
        case dishId          = "dish_id"
        case cookTimeMinutes = "cook_time_minutes"
        case cookingMethodId = "cooking_method_id"
        case totalSteps      = "total_steps"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dishId = c.lenientString(.dishId)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        cookTimeMinutes = c.lenientInt(.cookTimeMinutes)
        cookingMethodId = c.lenientString(.cookingMethodId)
        totalSteps = c.lenientInt(.totalSteps)
        steps = (try? c.decodeIfPresent([CookingStepDTO].self, forKey: .steps)) ?? []
        language = try c.decodeIfPresent(String.self, forKey: .language)
    }

    /// Chuẩn hoá giống bản Android: bỏ bước rỗng, sắp theo `step_no`.
    public func normalized(fallbackDishId: String) -> CookingStepsDTO {
        var copy = self
        copy.steps = steps
            .filter { !$0.instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.stepNo < $1.stepNo }
        if copy.dishId?.isEmpty ?? true { copy.dishId = fallbackDishId }
        if copy.totalSteps == nil { copy.totalSteps = copy.steps.count }
        return copy
    }
}

public struct CookingStepDTO: Equatable, Decodable, Identifiable, Sendable {
    public var id: Int { stepNo }
    public let stepNo: Int
    public let instruction: String
    /// Loại thao tác của bước (vd. `CUT_SLICE`), map sang Lottie qua `CookingAction(key:)`.
    public let actionType: String?

    public init(stepNo: Int, instruction: String, actionType: String? = nil) {
        self.stepNo = stepNo
        self.instruction = instruction
        self.actionType = actionType
    }

    enum CodingKeys: String, CodingKey {
        case instruction
        case stepNo     = "step_no"
        case actionType = "action_type"
        case actionTypeCamel = "actionType"
        case stepType   = "step_type"
        case type
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stepNo = c.lenientInt(.stepNo) ?? 0
        instruction = (try? c.decodeIfPresent(String.self, forKey: .instruction)) ?? ""
        actionType = c.lenientString(.actionType)
            ?? c.lenientString(.actionTypeCamel)
            ?? c.lenientString(.stepType)
            ?? c.lenientString(.type)
    }
}

// MARK: - Lenient decoding (server đôi khi trả số dạng chuỗi và ngược lại)

private extension KeyedDecodingContainer {
    func lenientInt(_ key: Key) -> Int? {
        if let v = try? decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? decodeIfPresent(Double.self, forKey: key) { return Int(v) }
        if let s = try? decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    func lenientString(_ key: Key) -> String? {
        if let s = try? decodeIfPresent(String.self, forKey: key) { return s }
        if let i = try? decodeIfPresent(Int.self, forKey: key) { return String(i) }
        return nil
    }
}
