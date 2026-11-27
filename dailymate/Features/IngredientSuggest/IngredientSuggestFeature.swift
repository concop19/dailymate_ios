//
//  IngredientSuggestFeature.swift
//  dailymate
//
//  Created by ManhLe on 11/23/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct IngredientSuggestFeature {
    @ObservableState
    struct State: Equatable {
        var searchParams: SearchParamsDTO
        var sections: [SuggestSectionDTO] = []
        var selectedIds: Set<Int> = []
        var isLoading = false
        var errorMessage: String?
        var isLoadingMore  = false
        var selectedCount: Int { selectedIds.count }
    }

    enum Action {
        case onAppear
        case retryTapped
        case response(Result<SuggestIngredientsResponseDTO, Error>)
        case ingredientToggled(Int)
        case continueButtonTapped
        case skipButtonTapped
        case delegate(Delegate)
        case loadingMoreTapped
        case loadMoreResponse(Result<SuggestIngredientsResponseDTO, Error>)
        @CasePathable
        enum Delegate: Equatable {
            case completed(SearchParamsDTO)
        }
    }

    @Dependency(\.homeClient) var homeClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.sections.isEmpty, !state.isLoading else { return .none }
                return fetchSuggestions(&state)
            case .loadingMoreTapped:
                guard !state.isLoading, !state.isLoadingMore else { return .none }
                let currentIds = state.sections.flatMap(\.items).map(\.id)
                let merged = Set(state.searchParams.excludeIds ?? []).union(currentIds)
                state.searchParams.excludeIds = Array(merged).sorted()

                // Chỉ giữ lại các nguyên liệu đã chọn, loại bỏ những món chưa chọn.
                state.sections = state.sections.map { section in
                    SuggestSectionDTO(
                        key: section.key,
                        items: section.items.filter { state.selectedIds.contains($0.id) },
                        emptyReason: section.emptyReason,
                        excluded: section.excluded
                    )
                }

                state.isLoadingMore = true
                state.errorMessage = nil
                let params = state.searchParams
                let homeClient = self.homeClient
                return .run { send in
                    await send(
                        .loadMoreResponse(
                            Result { try await homeClient.getIngredientSuggest(params) }
                        )
                    )
                }

            case let .loadMoreResponse(.success(result)):
                state.isLoadingMore = false
                let existingIds = Set(state.sections.flatMap(\.items).map(\.id))

                for newSection in result.sections {
                    let freshItems = newSection.items.filter { !existingIds.contains($0.id) }
                    guard !freshItems.isEmpty else { continue }

                    if let idx = state.sections.firstIndex(where: { $0.key == newSection.key }) {
                        let old = state.sections[idx]
                        state.sections[idx] = SuggestSectionDTO(
                            key: old.key,
                            items: old.items + freshItems,
                            emptyReason: newSection.emptyReason,
                            excluded: newSection.excluded
                        )
                    } else {
                        state.sections.append(
                            SuggestSectionDTO(
                                key: newSection.key,
                                items: freshItems,
                                emptyReason: newSection.emptyReason,
                                excluded: newSection.excluded
                            )
                        )
                    }
                }
                return .none

            case let .loadMoreResponse(.failure(error)):
                state.isLoadingMore = false
                state.errorMessage = error.localizedDescription
                return .none
            case .retryTapped:
                return fetchSuggestions(&state)

            case let .response(.success(result)):
                state.isLoading = false
                state.sections = result.sections
                let preselected = result.sections
                    .flatMap(\.items)
                    .filter(\.preselect)
                    .map(\.id)
                state.selectedIds = Set(preselected)
                return .none

            case let .response(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .ingredientToggled(id):
                if state.selectedIds.contains(id) {
                    state.selectedIds.remove(id)
                } else {
                    state.selectedIds.insert(id)
                }
                return .none

            case .continueButtonTapped:
                let params = SearchParamsBuilder.withIngredients(
                    base: state.searchParams,
                    ingredientIds: Array(state.selectedIds),
                    mode: .recommended
                )
                return .send(.delegate(.completed(params)))

            case .skipButtonTapped:
                let params = SearchParamsBuilder.withIngredients(
                    base: state.searchParams,
                    ingredientIds: [],
                    mode: .recommended
                )
                return .send(.delegate(.completed(params)))

            case .delegate:
                return .none
            }
        }
    }

    private func fetchSuggestions(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let params = state.searchParams
        let homeClient = self.homeClient
        return .run { send in
            await send(
                .response(
                    Result { try await homeClient.getIngredientSuggest(params) }
                )
            )
        }
    }
}
