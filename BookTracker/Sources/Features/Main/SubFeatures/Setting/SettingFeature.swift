//
//  SettingFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture

@Reducer
struct SettingFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
    }

    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case navigateButtonTapped(PathCase)

        enum PathCase: Equatable {
            case dataManage
//            case userGuide
//            case qna
//            case servicePolicy
//            case personalInfoPolicy
            case myInfo
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .navigateButtonTapped(let pathCase):
                switch pathCase {
                case .dataManage:
                    state.path.append(.dataManage(DataManageFeature.State()))
                case .myInfo:
                    state.path.append(.myInfo(MyInfoFeature.State()))
                }
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
    }
}

extension SettingFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case dataManage(DataManageFeature.State = .init())
            case myInfo(MyInfoFeature.State = .init())
        }

        enum Action: Equatable {
            case dataManage(DataManageFeature.Action)
            case myInfo(MyInfoFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.dataManage, action: \.dataManage) {
                DataManageFeature()
            }

            Scope(state: \.myInfo, action: \.myInfo) {
                MyInfoFeature()
            }
        }
    }
}
