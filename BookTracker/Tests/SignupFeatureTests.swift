@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct SignupFeatureTests {
    @Test func submitWithValidForm_triggersSignup() async {
        let store = TestStore(
            initialState: SignupFeature.State(
                email: "test@example.com",
                password: "password1",
                passwordConfirmation: "password1"
            ),
            reducer: { SignupFeature() }
        )

        store.dependencies.authService.signUp = { _, _ in
            throw CancellationError()
        }

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
            $0.isLoading = true
        }
    }

    @Test func submitWithInvalidForm_doesNotSignup() async {
        let store = TestStore(
            initialState: SignupFeature.State(
                email: "test@example.com",
                password: "short",
                passwordConfirmation: "short"
            ),
            reducer: { SignupFeature() }
        )

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
        }
    }

    @Test func submitWithMismatchedPasswords_doesNotSignup() async {
        let store = TestStore(
            initialState: SignupFeature.State(
                email: "test@example.com",
                password: "password1",
                passwordConfirmation: "password2"
            ),
            reducer: { SignupFeature() }
        )

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
        }
    }

    @Test func signupFailure_showsErrorAlert() async {
        let store = TestStore(
            initialState: SignupFeature.State(
                email: "test@example.com",
                password: "password1",
                passwordConfirmation: "password1"
            ),
            reducer: { SignupFeature() }
        )

        store.dependencies.authService.signUp = { _, _ in
            .failure(.auth(code: "conflict", status: 409, message: "Email already registered"))
        }

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
            $0.isLoading = true
        }

        await store.receive(\.loginResponse) {
            $0.isLoading = false
            $0.destination = .alert(.showErrorMessage(message: "Email already registered"))
        }
    }

    @Test func confirmSuccession_dismisses() async {
        let isDismissCalled = LockIsolated(false)

        let store = TestStore(
            initialState: SignupFeature.State(
                destination: .alert(.showSuccession())
            ),
            reducer: { SignupFeature() }
        )

        store.dependencies.dismiss = DismissEffect { isDismissCalled.setValue(true) }

        await store.send(.destination(.presented(.alert(.confirmSuccession)))) {
            $0.destination = nil
        }

        #expect(isDismissCalled.value == true)
    }

    @Test func formValidation_passwordRules() {
        var state = SignupFeature.State()
        state.email = "test@example.com"

        // Too short
        state.password = "abc1"
        state.passwordConfirmation = "abc1"
        #expect(state.isPasswordValid == false)

        // No number
        state.password = "abcdefgh"
        state.passwordConfirmation = "abcdefgh"
        #expect(state.isPasswordValid == false)

        // No letter
        state.password = "12345678"
        state.passwordConfirmation = "12345678"
        #expect(state.isPasswordValid == false)

        // Valid
        state.password = "password1"
        state.passwordConfirmation = "password1"
        #expect(state.isPasswordValid == true)
        #expect(state.isFormValid == true)
    }
}
