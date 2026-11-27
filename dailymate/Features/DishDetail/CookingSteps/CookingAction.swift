//
//  CookingAction.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import Foundation

/// 40 loại thao tác nấu ăn, mỗi loại một Lottie mèo đầu bếp lặp liền mạch trong
/// `Resources/Animation/cooking/<type>.json`.
enum CookingAction: String, CaseIterable, Sendable {
    case genericPrep = "GENERIC_PREP", washClean = "WASH_CLEAN", peelTrim = "PEEL_TRIM"
    case cutSlice = "CUT_SLICE", chopMince = "CHOP_MINCE", crushPound = "CRUSH_POUND"
    case tearShred = "TEAR_SHRED", soak = "SOAK", drain = "DRAIN", squeeze = "SQUEEZE"
    case marinate = "MARINATE", mixToss = "MIX_TOSS", whiskBeat = "WHISK_BEAT"
    case doughWork = "DOUGH_WORK", shapeWrap = "SHAPE_WRAP", blendPuree = "BLEND_PUREE"
    case strainFilter = "STRAIN_FILTER", preheatPan = "PREHEAT_PAN", addIngredient = "ADD_INGREDIENT"
    case pourLiquid = "POUR_LIQUID", seasonSprinkle = "SEASON_SPRINKLE", fryAromatics = "FRY_AROMATICS"
    case stirFry = "STIR_FRY", panFry = "PAN_FRY", fry = "FRY", flipTurn = "FLIP_TURN"
    case roastToast = "ROAST_TOAST", grill = "GRILL", bake = "BAKE", steam = "STEAM"
    case boil = "BOIL", blanch = "BLANCH", simmer = "SIMMER", braiseReduce = "BRAISE_REDUCE"
    case stewSlow = "STEW_SLOW", stir = "STIR", coverWait = "COVER_WAIT"
    case removeScoop = "REMOVE_SCOOP", stopHeat = "STOP_HEAT", plateServe = "PLATE_SERVE"

    /// Tên file Lottie trong bundle (không đuôi .json).
    var animationName: String { rawValue.lowercased() }

    /// Nhận "CUT_SLICE", "cut_slice", "cut-slice"…; không khớp thì trả nil.
    init?(key: String?) {
        guard let key else { return nil }
        let normalized = key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        self.init(rawValue: normalized)
    }

    static func resolve(_ key: String?) -> CookingAction {
        CookingAction(key: key) ?? .genericPrep
    }
}

/// Nhãn phương pháp nấu (`cooking_method_id`). Id dạng số (bảng mới) thì bỏ qua như bản RN.
enum CookingMethodLabel {
    static func label(for id: String?) -> String? {
        guard let id, !id.isEmpty, !id.allSatisfy(\.isNumber) else { return nil }
        switch id {
        case "nau_canh": return "Nấu canh"
        case "xao":      return "Xào"
        case "kho":      return "Kho"
        case "chien":    return "Chiên"
        case "nuong":    return "Nướng"
        case "hap":      return "Hấp"
        case "luoc":     return "Luộc"
        case "ham":      return "Hầm"
        case "tron_goi": return "Trộn / Gỏi"
        default:         return "Khác"
        }
    }
}
