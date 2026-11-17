import ComposableArchitecture
import SwiftUI

@main
struct dailymateApp: App {
    @MainActor static let store = Store(initialState: AppFeature.State()) {
           AppFeature()._printChanges()      // ✅ MỘT dòng duy nhất
       }
    var body: some Scene {
        WindowGroup {
            AppView(store: dailymateApp.store)
                // Nhận deep link: dailymate://auth-callback, dailymate://reset-password
                .onOpenURL { url in
                    dailymateApp.store.send(.openURL(url))
                }
        }
    }
}
