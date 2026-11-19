import ComposableArchitecture
import Foundation
internal import Auth

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        var home = HomeFeature.State()
        /// Có giá trị khi hồ sơ cần onboarding → hiển thị `OnboardingView` thay cho Home.
        var onboarding: OnboardingFeature.State?
        /// Đang chờ sự kiện `initialSession` đầu tiên — hiển thị màn chờ để tránh nháy màn hình.
        var isCheckingSession = true
        var isAuthenticated = false
        /// Đang tải hồ sơ khởi động từ Supabase sau khi đăng nhập.
        var isLoadingProfile = false
    }

    enum Action {
        case task
        case authStateChanged(userId: UUID?)
        case startupProfileLoaded(userId: UUID, Result<UserProfile, any Error>)
        case openURL(URL)
        case auth(AuthFeature.Action)
        case home(HomeFeature.Action)
        case onboarding(OnboardingFeature.Action)
    }

    private enum CancelID { case startupProfile }

    @Dependency(\.authClient) var authClient
    @Dependency(\.onboardingSupabaseClient) var onboardingSupabaseClient
    @Dependency(\.localClient) var localClient

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
                        await send(.authStateChanged(userId: change.session?.user.id))
                    }
                }

            case let .authStateChanged(userId):
                state.isCheckingSession = false
                let isAuthenticated = userId != nil
                guard state.isAuthenticated != isAuthenticated else { return .none }
                state.isAuthenticated = isAuthenticated
                // Làm mới form mỗi lần đăng nhập / đăng xuất.
                state.auth = AuthFeature.State()

                guard let userId else {
                    state.onboarding = nil
                    state.isLoadingProfile = false
                    return .cancel(id: CancelID.startupProfile)
                }

                // Đăng nhập → kiểm tra hồ sơ trên Supabase.
                state.isLoadingProfile = true
                let supabaseClient = self.onboardingSupabaseClient
                return .run { send in
                    do {
                        let profile = try await supabaseClient.loadStartupProfile()
                        await send(.startupProfileLoaded(userId: userId, .success(profile)))
                    } catch {
                        await send(.startupProfileLoaded(userId: userId, .failure(error)))
                    }
                }
                .cancellable(id: CancelID.startupProfile, cancelInFlight: true)

            case let .startupProfileLoaded(userId, result):
                state.isLoadingProfile = false
                // Lỗi tải hồ sơ → fallback về profile meta mặc định (profileId = "default").
                let profile = (try? result.get()) ?? OnboardingMapper.defaultStartupProfile()

                guard profile.needsOnboarding else {
                    state.onboarding = nil
                    return .none
                }
                // Khôi phục bản nháp nếu user từng làm dở.
                let draft = localClient.loadDraft(userId, profile.profileId) ?? OnboardingDraft()
                state.onboarding = OnboardingFeature.State(userId: userId, profile: profile, draft: draft)
                return .none

            case .onboarding(.delegate(.completed)):
                state.onboarding = nil
                return .none

            case let .openURL(url):
                let authClient = self.authClient
                return .run { _ in await authClient.handleOpenURL(url) }

            case .auth, .home, .onboarding:
                return .none
            }
        }
        .ifLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
