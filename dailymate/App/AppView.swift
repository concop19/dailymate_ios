import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        ZStack {
            if store.isCheckingSession {
                launchView
            } else if store.isAuthenticated {
                HomeView(store: store.scope(state: \.home, action: \.home))
                    .transition(.opacity)
            } else {
                AuthView(store: store.scope(state: \.auth, action: \.auth))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.isCheckingSession)
        .animation(.easeInOut(duration: 0.3), value: store.isAuthenticated)
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
        store: Store(initialState: AppFeature.State(isCheckingSession: false)) {
            AppFeature()
        }
    )
}
