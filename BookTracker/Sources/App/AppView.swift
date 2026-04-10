//
//  AppView.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if #available(iOS 17, *) {
                content
            } else {
                WithPerceptionTracking {
                    content
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .auth:
            if let authStore = store.scope(state: \.auth, action: \.auth) {
                AuthView(store: authStore)
            }

        case .main:
            if let mainStore = store.scope(state: \.main, action: \.main) {
                MainView(store: mainStore)
            }

        case .launching:
            VStack {
                Text("loading")
            }
            .task {
                store.send(.onAppear)
            }

        case .signingOut:
            VStack {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("signing_out")
            }
        }
    }
}
