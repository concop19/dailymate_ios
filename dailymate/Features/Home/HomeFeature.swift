import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    enum Action {
        case incrementButtonTapped
        case decrementButtonTapped
        case signOutButtonTapped
    }

    @Dependency(\.authClient) var authClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return .none
            case .decrementButtonTapped:
                state.count -= 1
                return .none
            case .signOutButtonTapped:
                let authClient = self.authClient
                return .run { _ in
                    try? await authClient.signOut()
                }
            }
        }
    }
}
