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
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case navigateButtonTapped(PathCase)
        case logoutButtonTapped
        case deleteAccountButtonTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum PathCase: Equatable {
            case dataManage
//            case userGuide
//            case qna
//            case servicePolicy
//            case personalInfoPolicy
            case myInfo
        }

        enum Alert: Equatable {
            case confirmLogout
            case confirmDeleteAccount
        }

        enum Delegate: Equatable {
            case logout
            case deleteAccount
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
            case .logoutButtonTapped:
                state.alert = .confirmLogout()
                return .none
            case .deleteAccountButtonTapped:
                state.alert = .confirmDeleteAccount()
                return .none
            case .alert(.presented(.confirmLogout)):
                return .send(.delegate(.logout))
            case .alert(.presented(.confirmDeleteAccount)):
                return .send(.delegate(.deleteAccount))
            case .alert:
                return .none
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
        .ifLet(\.$alert, action: \.alert)
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

extension AlertState where Action == SettingFeature.Action.Alert {
    static func confirmLogout() -> Self {
        Self {
            TextState("로그아웃 하시겠습니까?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmLogout) {
                TextState("로그아웃")
            }
        }
    }

    static func confirmDeleteAccount() -> Self {
        Self {
            TextState("정말 회원 탈퇴하시겠습니까?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteAccount) {
                TextState("회원 탈퇴")
            }
        }
    }
}
