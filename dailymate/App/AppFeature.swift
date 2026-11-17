import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        var home = HomeFeature.State()
        /// Đang chờ sự kiện `initialSession` đầu tiên — hiển thị màn chờ để tránh nháy màn hình.
        var isCheckingSession = true
        var isAuthenticated = false
    }

    enum Action {
        case task
        case authStateChanged(isAuthenticated: Bool)
        case openURL(URL)
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
    }

    @Dependency(\.authClient) var authClient

    var body: some Reducer<State, Action> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {
            case .task:
                let authClient = self.authClient
                return .run { send in
                    for await change in await authClient.authStateChanges() {
                        await send(.authStateChanged(isAuthenticated: change.session != nil))
                    }
                }

            case let .authStateChanged(isAuthenticated):
                state.isCheckingSession = false
                guard state.isAuthenticated != isAuthenticated else { return .none }
                state.isAuthenticated = isAuthenticated
                // Làm mới form mỗi lần đăng nhập / đăng xuất.
                state.auth = AuthFeature.State()
                return .none

            case let .openURL(url):
                let authClient = self.authClient
                return .run { _ in await authClient.handleOpenURL(url) }

            case .auth, .home:
                return .none
            }
        }
    }
}
