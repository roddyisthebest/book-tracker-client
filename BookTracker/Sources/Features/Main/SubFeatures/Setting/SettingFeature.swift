//
//  SettingFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SettingFeature {
    @Dependency(\.myInfoService) var myInfoService
    @Dependency(\.authService) var authService

    enum NotionPage: Equatable {
        case userGuide, faq

        var url: URL {
            let lang = Locale.current.language.languageCode?.identifier ?? ""
            let urlString: String
            switch (self, lang) {
            case (.userGuide, "ko"):
                urlString = "https://www.notion.so/BookTracker-iOS-34da9263b178804ea636e157fe618b4a"
            case (.userGuide, "ja"):
                urlString = "https://www.notion.so/BookTracker-iOS-34ea9263b178807f8d12d16bebec2c70"
            case (.userGuide, _):
                urlString = "https://www.notion.so/BookTracker-iOS-Screen-by-Screen-User-Guide-34ea9263b178807a9751e60bc2cb445a"
            case (.faq, "ko"):
                urlString = "https://www.notion.so/BookTracker-34ea9263b17880cbac36c461d32f0719"
            case (.faq, "ja"):
                urlString = "https://www.notion.so/BookTracker-34ea9263b17880249438ee375b3ce034"
            case (.faq, _):
                urlString = "https://www.notion.so/BookTracker-Frequently-Asked-Questions-34ea9263b1788069bd44d94b1f2c6716"
            }
            return URL(string: urlString)!
        }
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()

        var hasLoadedProfile: Bool = false

        var isFetching: Bool = false
        var isError: Bool = false

        var profile: MyProfile?
        var isDeletingAccount: Bool = false

        var safariURL: URL?

        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case onRefresh

        case onAppear
        case loadProfile
        case loadProfileResponse(Result<MyProfile, AppError>)

        case path(StackAction<Path.State, Path.Action>)
        case navigateButtonTapped(PathCase)
        case openPageButtonTapped(NotionPage)
        case safariDismissed
        case logoutButtonTapped
        case deleteAccountButtonTapped
        case deleteAccountSucceeded
        case deleteAccountFailed

        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum PathCase: Equatable {
            case dataManage
            case myInfo
            case termsOfService
            case privacyPolicy
        }

        enum Alert: Equatable {
            case confirmLogout
            case confirmDeleteAccount
            case confirmDeleteAccountFailed
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
                case .termsOfService:
                    state.path.append(.termsOfService)
                case .privacyPolicy:
                    state.path.append(.privacyPolicy)
                }
                return .none
            case .openPageButtonTapped(let page):
                state.safariURL = page.url
                return .none
            case .safariDismissed:
                state.safariURL = nil
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
                state.isDeletingAccount = true
                return .run { [authService] send in
                    let result = await authService.deleteAccountOnServer()
                    switch result {
                    case .success:
                        await send(.deleteAccountSucceeded)
                    case .failure:
                        await send(.deleteAccountFailed)
                    }
                }
            case .deleteAccountSucceeded:
                state.isDeletingAccount = false
                return .send(.delegate(.deleteAccount))
            case .deleteAccountFailed:
                state.isDeletingAccount = false
                state.alert = .deleteAccountFailed()
                return .none
            case .alert(.presented(.confirmDeleteAccountFailed)):
                return .none
            case .path(.element(_, .myInfo(.destination(.presented(.updateName(.delegate(.updateProfile(let profile)))))))):
                state.profile = profile
                return .none
            case .path(.element(_, .myInfo(.delegate(.updateProfile(let profile))))):
                state.profile = profile
                return .none
            case .path(.element(_, .dataManage(.dataResetButtonTapped))):
                state.path.append(.resetData(ResetDataFeature.State()))
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
            case resetData(ResetDataFeature.State = .init())
            case termsOfService
            case privacyPolicy
        }

        enum Action: Equatable {
            case dataManage(DataManageFeature.Action)
            case myInfo(MyInfoFeature.Action)
            case resetData(ResetDataFeature.Action)
            case termsOfService(Never)
            case privacyPolicy(Never)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.dataManage, action: \.dataManage) {
                DataManageFeature()
            }

            Scope(state: \.myInfo, action: \.myInfo) {
                MyInfoFeature()
            }

            Scope(state: \.resetData, action: \.resetData) {
                ResetDataFeature()
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

    static func deleteAccountFailed() -> Self {
        Self {
            TextState("delete_account_failed")
        } actions: {
            ButtonState(action: .confirmDeleteAccountFailed) {
                TextState("confirm")
            }
        }
    }
}
