//
//  SavedDishesFeature.swift
//  dailymate
//

import ComposableArchitecture
import Foundation

/// Danh sách món đã lưu cục bộ, hiển thị dạng ngăn kéo bên phải trên Home.
@Reducer
struct SavedDishesFeature {
    @ObservableState
    struct State: Equatable {
        var dishes: IdentifiedArrayOf<SavedDish> = []

        init(dishes: [SavedDish] = []) {
            self.dishes = IdentifiedArray(uniqueElements: dishes)
        }
    }

    enum Action {
        case onAppear
        case reload
        case deleteTapped(SavedDish.ID)
        case dishTapped(SavedDish)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case dishSelected(SavedDish)
        }
    }

    @Dependency(\.savedDishesClient) var savedDishesClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear, .reload:
                state.dishes = IdentifiedArray(uniqueElements: savedDishesClient.load())
                return .none

            case let .deleteTapped(id):
                state.dishes.remove(id: id)
                savedDishesClient.remove(id)
                return .none

            case let .dishTapped(dish):
                return .send(.delegate(.dishSelected(dish)))

            case .delegate:
                return .none
            }
        }
    }
}
