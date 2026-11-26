//
//  AnimationPlan.swift
//  dailymate
//
//  Created by ManhLe on 11/19/26.
//

import Foundation

/// Ánh xạ 18 avatar Lottie trong `Resources/Animation/plan/` theo giới tính và 8 nhóm tuổi (+ mặc định).
///
/// | Tuổi        | Nam               | Nữ                | Chưa chọn |
/// |-------------|-------------------|-------------------|-----------|
/// | chưa nhập   | kitten            | tabby_girl        | kitten    |
/// | <= 5        | boy_toddler_bong  | girl_toddler_sua  | kitten    |
/// | 6 ... 12    | boy_child_but_chi | girl_child_no     | kitten    |
/// | 13 ... 18   | boy_youth_beat    | girl_youth_may    | kitten    |
/// | 19 ... 29   | brother           | sister            | kitten    |
/// | 30 ... 44   | man_adult_moka    | woman_adult_la    | kitten    |
/// | 45 ... 59   | father            | mother            | kitten    |
/// | 60 ... 74   | man_senior_tra    | woman_senior_mai  | kitten    |
/// | >= 75       | grandpa           | grandma           | kitten    |
public enum AnimationPlan: String, CaseIterable, Equatable, Sendable {
    // Mặc định (chưa nhập năm sinh / chưa chọn giới tính)
    case kitten         = "kitten"
    case tabbyGirl      = "tabby_girl"

    // Nam (8 nhóm tuổi)
    case boyToddlerBong = "boy_toddler_bong"
    case boyChildButChi = "boy_child_but_chi"
    case boyYouthBeat   = "boy_youth_beat"
    case brother        = "brother"
    case manAdultMoka   = "man_adult_moka"
    case father         = "father"
    case manSeniorTra   = "man_senior_tra"
    case grandpa        = "grandpa"

    // Nữ (8 nhóm tuổi)
    case girlToddlerSua = "girl_toddler_sua"
    case girlChildNo    = "girl_child_no"
    case girlYouthMay   = "girl_youth_may"
    case sister         = "sister"
    case womanAdultLa   = "woman_adult_la"
    case mother         = "mother"
    case womanSeniorMai = "woman_senior_mai"
    case grandma        = "grandma"

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
        case (.male, ...5):      return .boyToddlerBong
        case (.female, ...5):    return .girlToddlerSua
        case (.male, 6...12):    return .boyChildButChi
        case (.female, 6...12):  return .girlChildNo
        case (.male, 13...18):   return .boyYouthBeat
        case (.female, 13...18): return .girlYouthMay
        case (.male, 19...29):   return .brother
        case (.female, 19...29): return .sister
        case (.male, 30...44):   return .manAdultMoka
        case (.female, 30...44): return .womanAdultLa
        case (.male, 45...59):   return .father
        case (.female, 45...59): return .mother
        case (.male, 60...74):   return .manSeniorTra
        case (.female, 60...74): return .womanSeniorMai
        case (.male, 75...):     return .grandpa
        case (.female, 75...):   return .grandma
        default:                 return .kitten
        }
    }
}
