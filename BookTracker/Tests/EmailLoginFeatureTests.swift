@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct EmailLoginFeatureTests {
    @Test func submitWithValidForm_triggersLogin() async {
        let store = TestStore(
            initialState: EmailLoginFeature.State(
                email: "test@example.com",
                password: "password123"
            ),
            reducer: { EmailLoginFeature() }
        )

        store.dependencies.authService.signIn = { _, _ in
            throw CancellationError()
        }

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
            $0.isLoading = true
        }

        // CancellationError is silently caught, isLoading stays true in store
        // but the effect is cancelled so no response is received
    }

    @Test func submitWithEmptyFields_doesNotLogin() async {
        let store = TestStore(
            initialState: EmailLoginFeature.State(),
            reducer: { EmailLoginFeature() }
        )

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
        }
        // No effect fired, no loginResponse expected
    }

    @Test func submitWithInvalidEmail_doesNotLogin() async {
        let store = TestStore(
            initialState: EmailLoginFeature.State(
                email: "invalid-email",
                password: "password123"
            ),
            reducer: { EmailLoginFeature() }
        )

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
        }
    }

    @Test func loginFailure_showsAlert() async {
        let store = TestStore(
            initialState: EmailLoginFeature.State(
                email: "test@example.com",
                password: "password123"
            ),
            reducer: { EmailLoginFeature() }
        )

        store.dependencies.authService.signIn = { _, _ in
            .failure(.auth(code: "invalid", status: 401, message: "Invalid credentials"))
        }

        await store.send(.submitButtonTapped) {
            $0.didAttemptSubmit = true
            $0.isLoading = true
        }

        await store.receive(\.loginResponse) {
            $0.isLoading = false
            $0.destination = .alert(.showErrorMessage(message: "Invalid credentials"))
        }
    }

    @Test func signupButtonTapped_delegatesSignupRequested() async {
        let store = TestStore(
            initialState: EmailLoginFeature.State(),
            reducer: { EmailLoginFeature() }
        )

        await store.send(.signupButtonTapped)
        await store.receive(\.delegate)
    }

    @Test func formValidation_properties() {
        var state = EmailLoginFeature.State()
        #expect(state.isFormValid == false)

        state.email = "test@example.com"
        state.password = "pass"
        #expect(state.isFormValid == true)

        state.email = "bad-email"
        #expect(state.isFormValid == false)
    }

    @Test func errorMessages_shownAfterAttempt() {
        var state = EmailLoginFeature.State()
        #expect(state.emailErrorToShow == nil)
        #expect(state.passwordErrorToShow == nil)

        state.didAttemptSubmit = true
        #expect(state.emailErrorToShow != nil)
        #expect(state.passwordErrorToShow != nil)
    }
}
