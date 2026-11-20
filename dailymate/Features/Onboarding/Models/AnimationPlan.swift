//
//  AnimationPlan.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import Foundation

/// Ánh xạ 8 avatar Lottie trong `Resources/Animation/plan/` theo giới tính và tuổi.
///
/// | Tuổi        | Nam       | Nữ          | Chưa chọn |
/// |-------------|-----------|-------------|-----------|
/// | chưa nhập   | kitten    | tabby-girl  | kitten    |
/// | <= 12       | kitten    | tabby-girl  | kitten    |
/// | 13 ... 29   | brother   | sister      | kitten    |
/// | 30 ... 54   | father    | mother      | kitten    |
/// | >= 55       | grandpa   | grandma     | kitten    |
public enum AnimationPlan: String, CaseIterable, Equatable, Sendable {
    case kitten    = "kitten"
    case tabbyGirl = "tabby-girl"
    case brother   = "brother"
    case sister    = "sister"
    case father    = "father"
    case mother    = "mother"
    case grandpa   = "grandpa"
    case grandma   = "grandma"

    /// Tên file JSON (không có đuôi) dùng cho `LottieView(animation: .named(...))`.
    public var animationName: String { rawValue }

    public static func resolve(
        gender: Gender?,
        birthYear: Int?,
        currentYear: Int = Calendar(identifier: .gregorian).component(.year, from: Date())
    ) -> Self {
        guard let birthYear, (1900...currentYear).contains(birthYear) else {
            return gender == .female ? .tabbyGirl : .kitten
        }
        let age = max(0, currentYear - birthYear)

        switch (gender, age) {
        case (.female, ...12):   return .tabbyGirl
        case (_, ...12):         return .kitten
        case (.male, 13...29):   return .brother
        case (.female, 13...29): return .sister
        case (.male, 30...54):   return .father
        case (.female, 30...54): return .mother
        case (.male, 55...):     return .grandpa
        case (.female, 55...):   return .grandma
        default:                 return .kitten
        }
    }
}
