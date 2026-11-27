//
//  DishDetailClient.swift
//  dailymate
//
//  Created by ManhLe on 11/27/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
public struct DishDetailClient: Sendable {
    public var getDishDetail: @Sendable (_ dishId: String) async throws -> DishDetailDTO
    public var sendFeedback: @Sendable (_ request: FeedbackRequestDTO) async throws -> Void
    public var getCookingSteps: @Sendable (_ dishId: String) async throws -> CookingStepsDTO
}

extension DishDetailClient: DependencyKey {
    public static var liveValue: Self {
        @Dependency(\.backendClient) var backend
        return Self(
            getDishDetail: { dishId in
                try await backend.request(.dishDetail(dishId), as: DishDetailDTO.self)
            },
            sendFeedback: { request in
                try await backend.requestVoid(try .dishFeedback(request))
            },
            getCookingSteps: { dishId in
                try await backend
                    .request(.cookingSteps(dishId), as: CookingStepsDTO.self)
                    .normalized(fallbackDishId: dishId)
            }
        )
    }

    public static var previewValue: Self {
        Self(
            getDishDetail: { dishId in
                DishDetailDTO(
                    id: dishId,
                    title: "Thịt kho tiêu xanh",
                    url: nil,
                    description: "Món mặn đậm đà, thơm mùi tiêu xanh, hợp ăn nóng với cơm trắng.",
                    nation: "vietnam",
                    imageUrl: nil,
                    cookTimeMinutes: 30,
                    estCostVnd: 65000,
                    estCostLevel: 2,
                    cuisineRegion: "southern",
                    specialtyOrigin: "Nam Bộ",
                    servingSize: "toàn bộ công thức món ăn",
                    ingredients: [
                        DishIngredientDTO(id: 102, name: "Thịt heo ba chỉ", nameEn: "pork belly", category: "whole_food", quantityG: 300, isMain: 1),
                        DishIngredientDTO(id: 215, name: "Tiêu xanh", nameEn: "green peppercorn", category: "spice_herb", quantityG: 20, isMain: 1),
                        DishIngredientDTO(id: 301, name: "Nước mắm", nameEn: "fish sauce", category: "condiment", quantityG: 15, isMain: 0),
                        DishIngredientDTO(id: 302, name: "Hành tím", nameEn: "shallot", category: "spice_herb", quantityG: 10, isMain: 0),
                    ]
                )
            },
            sendFeedback: { _ in },
            getCookingSteps: { dishId in
                CookingStepsDTO(
                    dishId: dishId,
                    title: "Thịt kho tiêu xanh",
                    cookTimeMinutes: 30,
                    cookingMethodId: "kho",
                    steps: [
                        CookingStepDTO(stepNo: 1, instruction: "Rửa sạch thịt ba chỉ, chần qua nước sôi rồi để ráo.", actionType: "BLANCH"),
                        CookingStepDTO(stepNo: 2, instruction: "Thái thịt thành miếng vừa ăn, dày khoảng 1 cm.", actionType: "CUT_SLICE"),
                        CookingStepDTO(stepNo: 3, instruction: "Ướp thịt với nước mắm, đường, hành tím băm trong 20 phút.", actionType: "MARINATE"),
                        CookingStepDTO(stepNo: 4, instruction: "Phi thơm hành tím rồi cho thịt vào đảo săn.", actionType: "FRY_AROMATICS"),
                        CookingStepDTO(stepNo: 5, instruction: "Thêm nước dừa, kho lửa nhỏ 25 phút cho thịt mềm, nước sệt lại.", actionType: "BRAISE_REDUCE"),
                        CookingStepDTO(stepNo: 6, instruction: "Cho tiêu xanh vào, đun thêm 3 phút rồi tắt bếp, bày ra đĩa.", actionType: "PLATE_SERVE"),
                    ],
                    language: "vi"
                )
            }
        )
    }

    public static var testValue: Self {
        Self()
    }
}

extension DependencyValues {
    public var dishDetailClient: DishDetailClient {
        get { self[DishDetailClient.self] }
        set { self[DishDetailClient.self] = newValue }
    }
}
