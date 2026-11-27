import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        ZStack {
            if store.isCheckingSession || (store.isAuthenticated && store.isLoadingProfile) {
                AppLoadingView()
                    .transition(.opacity)
            } else if store.isAuthenticated {
                if let onboardingStore = store.scope(state: \.onboarding, action: \.onboarding) {
                    OnboardingView(store: onboardingStore)
                        .transition(.opacity)
                } else {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                        .transition(.opacity)
                }
            } else {
                AuthView(store: store.scope(state: \.auth, action: \.auth))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isCheckingSession)
        .animation(.easeInOut(duration: 0.3), value: store.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: store.isLoadingProfile)
        .animation(.easeInOut(duration: 0.3), value: store.onboarding == nil)
        .task { await store.send(.task).finish() }
    }

    private var launchView: some View {
        ProgressView()
            .tint(Color.Ghibli.cream)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { BackgroundView() }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State(isCheckingSession: true)) {
            AppFeature()
        }
    )
}
