//
//  MainView.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture
import SwiftUI

struct MainView: View {
    let store: StoreOf<MainFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TabView(
                selection: viewStore.binding(
                    get: \.selectedTab,
                    send: MainFeature.Action.tabSelected
                )
            ) {
                Text("Home")
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(MainTab.home)

                Text("Search")
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(MainTab.search)

                NavigationStack {
                    LibraryView(
                        store: store.scope(
                            state: \.library,
                            action: \.library
                        )
                    )
                }
                .tabItem { Label("Books", systemImage: "books.vertical") }
                .tag(MainTab.library)

                Text("Stats")
                    .tabItem { Label("Stats", systemImage: "chart.bar") }
                    .tag(MainTab.stats)

                Text("Settings")
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(MainTab.settings)
            }
        }
    }
}
