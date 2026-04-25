//
//  SettingFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture

@Reducer
struct SettingFeature {
    @Dependency(\.myInfoService) var myInfoService

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()

        var hasLoadedProfile: Bool = false

        var isFetching: Bool = false
        var isError: Bool = false

        var profile: MyProfile?

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case onRefresh

        case onAppear
        case loadProfile
        case loadProfileResponse(Result<MyProfile, AppError>)

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
            case .onAppear:
                guard !state.hasLoadedProfile else { return .none }
                state.hasLoadedProfile = true
                return .send(.loadProfile)
            case .onRefresh:
                return .send(.loadProfile)
            case .loadProfile:
                state.isFetching = true
                state.isError = false
                return .run {
                    send in
                    let result = await myInfoService.loadProfile()
                    await send(.loadProfileResponse(result))
                }
            case .loadProfileResponse(.success(let profile)):
                state.isFetching = false
                state.profile = profile
                return .none
            case .loadProfileResponse(.failure):
                state.isFetching = false
                state.isError = true
                return .none
            case .navigateButtonTapped(let pathCase):
                switch pathCase {
                case .dataManage:
                    state.path.append(.dataManage(DataManageFeature.State()))
                case .myInfo:
                    guard let profile = state.profile else {
                        return .none
                    }
                    state.path.append(.myInfo(MyInfoFeature.State(profile: profile)))
                }
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
            case .path(.element(_, .myInfo(.destination(.presented(.updateName(.delegate(.updateProfile(let profile)))))))):
                state.profile = profile
                return .none
            case .path(.element(_, .myInfo(.delegate(.updateProfile(let profile))))):
                state.profile = profile
                return .none
            case .path:
                return .none
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
            TextState("confirm_logout")
        } actions: {
            ButtonState(role: .destructive, action: .confirmLogout) {
                TextState("logout")
            }
        }
    }

    static func confirmDeleteAccount() -> Self {
        Self {
            TextState("confirm_delete_account")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteAccount) {
                TextState("delete_account")
            }
        }
    }
}
