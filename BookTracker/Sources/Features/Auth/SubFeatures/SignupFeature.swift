//
//  SignupFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//

import ComposableArchitecture
import Foundation
import Supabase

@Reducer
struct SignupFeature {
    @ObservableState
    struct State: Equatable {
        var email: String = ""
        var password: String = ""
        var passwordConfirmation: String = ""
        var didAttemptSubmit: Bool = false

        var isLoading: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case submitButtonTapped

        case loginResponse(Result<AuthResponse, AppError>)

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmSuccession
        }
    }

    @Dependency(\.authService) var authService
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .submitButtonTapped:
                state.didAttemptSubmit = true
                if state.isFormValid {
                    state.isLoading = true
                    return .run { [email = state.email, password = state.password] send in
                        let result = try await authService.signUp(email, password)
                        await send(.loginResponse(result))
                    } catch: { error, send in
                        if error is CancellationError { return }
                        let appError = AppError.map(error)
                        await send(.loginResponse(.failure(appError)))
                    }
                }
                return .none
            case .loginResponse(let result):
                state.isLoading = false
                switch result {
                case .success:
                    state.destination = .alert(.showSuccession())
                case .failure(let error):
                    switch error {
                    case .auth(let code, let status, let message):
                        print(code, status)
                        state.destination = .alert(.showErrorMessage(message: message))
                        return .none
                    default:
                        return .none
                    }
                }
                return .none
            case .destination(.presented(.alert(.confirmSuccession))):
                return .run {
                    _ in
                    await self.dismiss()
                }
            case .binding:
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SignupFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case alert(AlertState<SignupFeature.Action.Alert>)
    }
}

extension SignupFeature.State {
    var isEmailValid: Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    var isPasswordValid: Bool {
        // 최소 8자, 숫자/문자 포함
        let hasMinLength = password.count >= 8
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasMinLength && hasLetter && hasNumber
    }

    var doPasswordsMatch: Bool {
        !password.isEmpty && password == passwordConfirmation
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid && doPasswordsMatch
    }

    // 뷰 표시용 에러 메시지(필요 시)
    var emailError: String? {
        if email.isEmpty { return String(localized: "enter_email_placeholder") }
        return isEmailValid ? nil : String(localized: "invalid_email_format")
    }

    var passwordError: String? {
        if password.isEmpty { return String(localized: "enter_password_placeholder") }
        if password.count < 8 { return String(localized: "password_min_length") }
        if password.range(of: "[A-Za-z]", options: .regularExpression) == nil {
            return String(localized: "password_needs_letter")
        }
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            return String(localized: "password_needs_number")
        }
        return nil
    }

    var passwordConfirmationError: String? {
        if passwordConfirmation.isEmpty { return String(localized: "enter_password_confirm") }
        return doPasswordsMatch ? nil : String(localized: "password_mismatch")
    }

    var emailErrorToShow: String? {
        didAttemptSubmit ? emailError : nil
    }

    var passwordErrorToShow: String? {
        didAttemptSubmit ? passwordError : nil
    }

    var passwordConfirmationErrorToShow: String? {
        didAttemptSubmit ? passwordConfirmationError : nil
    }
}

extension AlertState where Action == SignupFeature.Action.Alert {
    static func showErrorMessage(message: String?) -> Self {
        Self {
            TextState(message ?? String(localized: "error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        }
    }

    static func showSuccession() -> Self {
        Self {
            TextState("signup_success")
        } actions: {
            ButtonState(action: .confirmSuccession) {
                TextState("confirm")
            }
        }
    }
}
