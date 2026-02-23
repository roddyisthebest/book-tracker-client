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
                NavigationStack {
                    HomeView(
                        store: store.scope(
                            state: \.home,
                            action: \.home
                        )
                    )
                }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(MainTab.home)

                NavigationStack {
                    SearchView(
                        store: store.scope(
                            state: \.search,
                            action: \.search
                        ),
                        isSheet: false
                    )
                }
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

                NavigationStack {
                    StatView(
                        store: store.scope(
                            state: \.stat,
                            action: \.stat
                        )
                    )
                }
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(MainTab.stat)

                NavigationStack {
                    SettingView(
                        store: store.scope(
                            state: \.setting,
                            action: \.setting
                        )
                    )
                }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(MainTab.setting)
            }
        }
    }
}
