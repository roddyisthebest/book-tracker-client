//
//  AuthFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture
import Foundation

enum SnsLoginMethod: Equatable {
    case apple
    case google
}

@Reducer
struct AuthFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        @Presents var alert: AlertState<Action.Alert>?
        var isAppleLoginLoading: Bool = false
        var isGoogleLoginLoading: Bool = false
    }

    enum Action {
        case path(StackAction<Path.State, Path.Action>)
        case snsLoginButtonTapped(SnsLoginMethod)
        case emailLoginButtonTapped

        case appleLoginFailed
        case googleLoginFailed
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}

        case delegate(Delegate)

        enum Delegate: Equatable {
            case login
        }
    }

    @Dependency(\.authService) var authService
    @Dependency(\.appleAuthClient) var appleAuthClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .snsLoginButtonTapped(let method):
                switch method {
                case .apple:
                    state.isAppleLoginLoading = true
                    return .run { send in
                        do {
                            let payload = try await appleAuthClient.signIn()
                            _ = try await authService.appleSignIn(payload.idToken, payload.nonce)
                            await send(.delegate(.login))
                        } catch {
                            print(error)
                            await send(.appleLoginFailed)
                        }
                    }
                    .cancellable(id: "apple-login", cancelInFlight: true)
                case .google:
                    state.isGoogleLoginLoading = true

                    return .run { send in
                        do {
                            _ = try await authService.googleSignIn()
                            await send(.delegate(.login))
                        } catch {
                            print(error)
                            await send(.googleLoginFailed)
                        }
                    }
                }
            //                    return .send(.delegate(.login))
            case .emailLoginButtonTapped:
                state.path.append(.emailLogin(EmailLoginFeature.State()))
                return .none
            case .delegate:
                return .none
            case .alert:
                return .none
            case .path(.element(id: _, action: .emailLogin(.delegate(.signupRequested)))):
                state.path.append(.signup(SignupFeature.State()))
                return .none
            case .path(.element(id: _, action: .emailLogin(.delegate(.signin)))):
                return .send(.delegate(.login))
            case .path:
                return .none
            case .appleLoginFailed:
                state.isAppleLoginLoading = false
                state.alert = .showErrorMsg()

                return .none
            case .googleLoginFailed:
                state.isGoogleLoginLoading = false
                state.alert = .showErrorMsg()
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AuthFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case emailLogin(EmailLoginFeature.State = .init())
            case signup(SignupFeature.State = .init())
        }

        enum Action: Equatable {
            case emailLogin(EmailLoginFeature.Action)
            case signup(SignupFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.emailLogin, action: \.emailLogin) {
                EmailLoginFeature()
            }

            Scope(state: \.signup, action: \.signup) {
                SignupFeature()
            }
        }
    }
}

extension AlertState where Action == AuthFeature.Action.Alert {
    static func showErrorMsg() -> Self {
        Self {
            TextState("에러입니다.")
        } actions: {}
    }
}
