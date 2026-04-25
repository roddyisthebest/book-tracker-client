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
        var stat = StatFeature.State()
        var setting = SettingFeature.State()
    }

    enum Action: Equatable {
        case tabSelected(MainTab)
        case library(LibraryFeature.Action)
        case search(SearchFeature.Action)
        case home(HomeFeature.Action)
        case stat(StatFeature.Action)
        case setting(SettingFeature.Action)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case logout
            case deleteAccount
        }
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

        Scope(state: \.stat, action: \.stat) {
            StatFeature()
        }

        Scope(state: \.setting, action: \.setting) {
            SettingFeature()
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
            case .stat:
                return .none
            case .setting(.delegate(.logout)):
                return .send(.delegate(.logout))
            case .setting(.delegate(.deleteAccount)):
                return .send(.delegate(.deleteAccount))
            case .setting(.delegate(.appDataDeleted)):
                state.search.destination = .suggestions(SearchSuggestionsFeature.State())
                state.home.didInitialLoad = false
                return .none
            case .setting(.delegate(.serverDataDeleted)):
                state.home.didInitialLoad = false
                return .send(.library(.onAppear))

            case .setting:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
