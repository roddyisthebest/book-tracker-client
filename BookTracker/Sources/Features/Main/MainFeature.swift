//
//  MainFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture

@Reducer
struct MainFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: MainTab = .home

        var library = LibraryFeature.State()
        var search = SearchFeature.State()
        var home = HomeFeature.State()
    }

    enum Action: Equatable {
        case tabSelected(MainTab)
        case library(LibraryFeature.Action)
        case search(SearchFeature.Action)
        case home(HomeFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.library, action: \.library) { // ⬅️ 추가
            LibraryFeature()
        }

        Scope(state: \.search, action: \.search) {
            SearchFeature()
        }

        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
            case .library:
                return .none
            case .search:
                return .none
            case .home:
                return .none
            }
        }
    }
}
