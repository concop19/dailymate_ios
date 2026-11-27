//
//  DishDetailFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct DishDetailFeature {
    enum Tab: Int, CaseIterable, Identifiable, Equatable, Sendable {
        case ingredients = 0
        case why = 1
        case info = 2

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .ingredients: "Nguyên liệu"
            case .why:         "Vì sao hợp"
            case .info:        "Thông tin"
            }
        }
    }

    enum FeedbackState: Equatable, Sendable {
        case idle
        case loading
        case done
        case error
    }

    @ObservableState
    struct State: Equatable {
        var dish: RankedDishDTO
        var detail: DishDetailDTO?
        var pickedIngredientIds: Set<Int>
        var selectedTab: Tab = .ingredients
        var isLoadingDetail: Bool = false
        var errorMessage: String?
        var isSaved: Bool = false
        var feedbackStates: [DishFeedbackAction: FeedbackState] = [:]
        var toastMessage: String?

        init(
            dish: RankedDishDTO,
            pickedIngredientIds: Set<Int> = []
        ) {
            self.dish = dish
            self.pickedIngredientIds = pickedIngredientIds
        }

        var ingredients: [DishIngredientDTO] { detail?.ingredients ?? [] }
        var mainIngredients: [DishIngredientDTO] { detail?.mainIngredients ?? [] }
        var sideIngredients: [DishIngredientDTO] { detail?.sideIngredients ?? [] }
        var matchPct: Int { dish.resolvedMatchPct }
    }

    enum Action {
        case onAppear
        case retryDetailTapped
        case detailResponse(Result<DishDetailDTO, Error>)
        case tabSelected(Tab)
        case toggleSaveTapped
        case sendFeedback(DishFeedbackAction)
        case feedbackResponse(DishFeedbackAction, Result<Void, Error>)
        case resetFeedbackError(DishFeedbackAction)
        case cookNowTapped
        case backTapped
        case dismissToast
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case cookNow(RankedDishDTO, DishDetailDTO?)
        }
    }

    private enum CancelID : Hashable{
        case fetchDetail
        case toast
        case feedbackReset(DishFeedbackAction)
    }

    @Dependency(\.dishDetailClient) var dishDetailClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.savedDishesClient) var savedDishesClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isSaved = savedDishesClient.isSaved(state.dish.dishId)
                guard state.detail == nil, !state.isLoadingDetail else { return .none }
                return fetchDetail(&state)

            case .retryDetailTapped:
                return fetchDetail(&state)

            case let .detailResponse(.success(detail)):
                state.isLoadingDetail = false
                state.errorMessage = nil
                state.detail = detail
                state.dish = state.dish.merged(with: detail)
                return .none

            case let .detailResponse(.failure(error)):
                state.isLoadingDetail = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .toggleSaveTapped:
                // Chỉ lưu cục bộ trên máy, không gọi backend.
                state.isSaved = savedDishesClient.toggle(SavedDish(dish: state.dish))
                let message = state.isSaved
                    ? "Đã lưu \"\(state.dish.title)\""
                    : "Đã bỏ lưu \"\(state.dish.title)\""
                return showToast(message, state: &state)

            case let .sendFeedback(feedbackAction):
                let current = state.feedbackStates[feedbackAction] ?? .idle
                guard current == .idle || current == .error else { return .none }
                state.feedbackStates[feedbackAction] = .loading

                let request = FeedbackRequestDTO(
                    sessionUuid: "",
                    dishId: state.dish.dishId,
                    action: feedbackAction,
                    feedbackAt: ISO8601DateFormatter().string(from: Date())
                )
                let client = self.dishDetailClient
                return .run { send in
                    await send(
                        .feedbackResponse(
                            feedbackAction,
                            Result { try await client.sendFeedback(request) }
                        )
                    )
                }

            case let .feedbackResponse(feedbackAction, .success):
                state.feedbackStates[feedbackAction] = .done
                return .none

            case let .feedbackResponse(feedbackAction, .failure):
                state.feedbackStates[feedbackAction] = .error
                let clock = self.clock
                return .run { send in
                    try? await clock.sleep(for: .seconds(2))
                    await send(.resetFeedbackError(feedbackAction))
                }
                .cancellable(id: CancelID.feedbackReset(feedbackAction), cancelInFlight: true)

            case let .resetFeedbackError(feedbackAction):
                if state.feedbackStates[feedbackAction] == .error {
                    state.feedbackStates[feedbackAction] = .idle
                }
                return .none

            case .cookNowTapped:
                return .send(.delegate(.cookNow(state.dish, state.detail)))

            case .backTapped:
                let dismiss = self.dismiss
                return .run { _ in await dismiss() }

            case .dismissToast:
                state.toastMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func fetchDetail(_ state: inout State) -> Effect<Action> {
        state.isLoadingDetail = true
        state.errorMessage = nil
        let dishId = state.dish.dishId
        let client = self.dishDetailClient
        return .run { send in
            await send(
                .detailResponse(
                    Result { try await client.getDishDetail(dishId) }
                )
            )
        }
        .cancellable(id: CancelID.fetchDetail, cancelInFlight: true)
    }

    private func showToast(_ message: String, state: inout State) -> Effect<Action> {
        state.toastMessage = message
        let clock = self.clock
        return .run { send in
            try? await clock.sleep(for: .seconds(2))
            await send(.dismissToast)
        }
        .cancellable(id: CancelID.toast, cancelInFlight: true)
    }
}
