import ComposableArchitecture
import SwiftUI
import UIKit

@main
struct BookTrackerApp: App {
    init() {
        configureSegmentedControl()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: AppFeature.State.launching, reducer: {
                AppFeature()
            }))
        }
    }

    private func configureSegmentedControl() {
        let tintColor = UIColor.systemBlue

        let selectedText = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark
                ? .white
                : .white
        })
        let normalText = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.7)
                : UIColor.black.withAlphaComponent(0.6)
        })

        UISegmentedControl.appearance().selectedSegmentTintColor = tintColor
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: selectedText,
            .font: UIFont.systemFont(ofSize: 14, weight: .bold)
        ], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: normalText,
            .font: UIFont.systemFont(ofSize: 14, weight: .medium)
        ], for: .normal)
    }
}
