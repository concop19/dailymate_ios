//
//  DishListFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/26/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct DishListFeature {
    static let pageSize = 10

    @ObservableState
    struct State: Equatable {
        /// Body gửi `/api/v1/recommend` (cố định `recentDishIds` từ trang 1 để ăn cache 10 phút trên server).
        var requestParams: SearchParamsDTO
        var dishes: [RankedDishDTO] = []
        var page: Int = 1
        var totalPages: Int = 1
        var hasNextPage: Bool = false
        var totalDishes: Int = 0
        var basketWarningCount: Int?
        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var errorMessage: String?

        init(baseParams: SearchParamsDTO) {
            self.requestParams = baseParams
        }
    }

    enum Action {
        case onAppear
        case retryTapped
        case loadNextPageTapped
        case pageResponse(page: Int, Result<RecommendResponseDTO, Error>)
        case dishTapped(RankedDishDTO)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case dishSelected(RankedDishDTO)
        }
    }

    private enum CancelID {
        case recommend
    }

    @Dependency(\.homeClient) var homeClient
    @Dependency(\.localClient) var localClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.dishes.isEmpty, !state.isLoading else { return .none }
                state.requestParams.recentDishIds = localClient.loadRecentDishIds()
                state.requestParams.pageSize = Self.pageSize
                return fetchPage(1, state: &state)

            case .retryTapped:
                state.requestParams.recentDishIds = localClient.loadRecentDishIds()
                state.requestParams.pageSize = Self.pageSize
                return fetchPage(1, state: &state)

            case .loadNextPageTapped:
                guard !state.isLoading, !state.isLoadingMore, state.hasNextPage else {
                    return .none
                }
                return fetchPage(state.page + 1, state: &state)

            case let .pageResponse(requestedPage, .success(response)):
                state.isLoading = false
                state.isLoadingMore = false
                state.errorMessage = nil

                if requestedPage == 1 {
                    state.dishes = response.rankedDishes
                    state.basketWarningCount = response.basketWarning?.count
                } else {
                    let existingIds = Set(state.dishes.map(\.dishId))
                    let fresh = response.rankedDishes.filter { !existingIds.contains($0.dishId) }
                    state.dishes.append(contentsOf: fresh)
                }

                state.page = response.page ?? requestedPage
                state.totalPages = response.totalPages ?? max(1, state.page)
                state.hasNextPage = response.hasNextPage
                state.totalDishes = response.totalDishes ?? state.dishes.count
                return .none

            case let .pageResponse(_, .failure(error)):
                state.isLoading = false
                state.isLoadingMore = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .dishTapped(dish):
                let current = localClient.loadRecentDishIds().filter { $0 != dish.dishId }
                let updated = Array(([dish.dishId] + current).prefix(3))
                localClient.saveRecentDishIds(updated)
                return .send(.delegate(.dishSelected(dish)))

            case .delegate:
                return .none
            }
        }
    }

    private func fetchPage(_ page: Int, state: inout State) -> Effect<Action> {
        if page == 1 {
            state.isLoading = true
            state.errorMessage = nil
        } else {
            state.isLoadingMore = true
        }

        var body = state.requestParams
        body.page = page
        body.pageSize = Self.pageSize

        let homeClient = self.homeClient
        return .run { send in
            await send(
                .pageResponse(
                    page: page,
                    Result { try await homeClient.recommendDishes(body) }
                )
            )
        }
        .cancellable(id: CancelID.recommend, cancelInFlight: page == 1)
    }
}
