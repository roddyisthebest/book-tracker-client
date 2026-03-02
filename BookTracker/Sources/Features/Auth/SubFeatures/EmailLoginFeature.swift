//
//  EmailLoginFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//

import ComposableArchitecture
import Foundation
import Supabase

@Reducer
struct EmailLoginFeature {
    @ObservableState
    struct State: Equatable {
        var email: String = ""
        var password: String = ""
        var didAttemptSubmit: Bool = false
        var isLoading: Bool = false
        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case submitButtonTapped
        case signupButtonTapped
        case loginResponse(Result<Session, AppError>)

        case delegate(Delegate)

        enum Delegate: Equatable {
            case signupRequested
            case signin
        }

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmError
        }
    }

    @Dependency(\.authService) var authService

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .submitButtonTapped:
                state.didAttemptSubmit = true
                if state.isFormValid {
                    state.isLoading = true

                    return .run { [email = state.email, password = state.password] send in
                        let result = try await authService.signIn(email, password)
                        await send(.loginResponse(result))
                    } catch: { error, send in
                        if error is CancellationError { return }
                        let appError = AppError.map(error)
                        await send(.loginResponse(.failure(appError)))
                    }
                }

                return .none

            case .signupButtonTapped:
                return .send(.delegate(.signupRequested))

            case .loginResponse(let result):
                state.isLoading = false
                switch result {
                case .success(let session):
                    return .send(.delegate(.signin))
                case .failure(let error):
                    switch error {
                    case .auth(let code, let status, let message):
                        state.destination = .alert(.showErrorMessage(message: message))
                        return .none
                    default:
                        return .none
                    }
                }

            case .binding:
                return .none

            case .delegate:
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension EmailLoginFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case alert(AlertState<EmailLoginFeature.Action.Alert>)
    }
}

extension EmailLoginFeature.State {
    var isEmailValid: Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    var isPasswordValid: Bool {
        !password.isEmpty
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }

    // 뷰 표시용 에러 메시지(필요 시)
    var emailError: String? {
        if email.isEmpty { return "이메일을 입력해주세요" }
        return isEmailValid ? nil : "올바른 이메일 형식이 아니에요."
    }

    var passwordError: String? {
        if password.isEmpty { return "비밀번호를 입력해주세요" }

        return nil
    }

    var emailErrorToShow: String? {
        didAttemptSubmit ? emailError : nil
    }

    var passwordErrorToShow: String? {
        didAttemptSubmit ? passwordError : nil
    }
}

extension AlertState where Action == EmailLoginFeature.Action.Alert {
    static func showErrorMessage(message: String?) -> Self {
        Self {
            TextState(message ?? "에러발생")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        }
    }
}
