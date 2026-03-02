import ComposableArchitecture
import SwiftUI

@main
struct BookTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State.launching, reducer: {
                AppFeature()
            }))
        }
    }
}
