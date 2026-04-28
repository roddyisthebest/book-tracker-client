//
//  MainFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture
import Sharing

@Reducer
struct MainFeature {
    @Dependency(\.myInfoService) var myInfoService

    @ObservableState
    struct State: Equatable {
        var selectedTab: MainTab = .home
        @Shared(.userProfile) var profile: MyProfile?

        var library = LibraryFeature.State()
        var search = SearchFeature.State()
        var home = HomeFeature.State()
        var stat = StatFeature.State()
        var setting = SettingFeature.State()
    }

    enum Action: Equatable {
        case onAppear
        case loadProfileResponse(Result<MyProfile, AppError>)

        case tabSelected(MainTab)
        case library(LibraryFeature.Action)
        case search(SearchFeature.Action)
        case home(HomeFeature.Action)
        case stat(StatFeature.Action)
        case setting(SettingFeature.Action)
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
            case .onAppear:
                guard state.profile == nil else { return .none }
                return .run { [myInfoService] send in
                    let result = await myInfoService.loadProfile()
                    await send(.loadProfileResponse(result))
                }
            case .loadProfileResponse(.success(let profile)):
                state.$profile.withLock { $0 = profile }
                return .none
            case .loadProfileResponse(.failure):
                return .none
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
            case .setting(.path(.element(_, .resetData(.delegate(.appDataDeleted))))):
                state.search.destination = .suggestions(SearchSuggestionsFeature.State())
                state.home.didInitialLoad = false
                return .none
            case .setting(.path(.element(_, .resetData(.delegate(.serverDataDeleted))))):
                state.home.didInitialLoad = false
                return .send(.library(.onAppear))
            case .setting:
                return .none
            }
        }
    }
}
