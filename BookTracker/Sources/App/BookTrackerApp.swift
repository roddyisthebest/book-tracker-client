import SwiftUI
import ComposableArchitecture

@main
struct BookTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State.main(MainFeature.State()), reducer: {
                AppFeature()
            }))
        }
    }
}
