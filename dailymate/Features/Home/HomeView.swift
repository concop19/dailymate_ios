import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)

                Text("Welcome to DailyMate")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Count: \(store.count)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack(spacing: 16) {
                    Button {
                        store.send(.decrementButtonTapped)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        store.send(.incrementButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button(role: .destructive) {
                    store.send(.signOutButtonTapped)
                } label: {
                    Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.bordered)
                .padding(.top, 16)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
