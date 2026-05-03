@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct AuthFeatureTests {
    @Test func emailLoginButtonTapped_appendsPath() async {
        let store = TestStore(
            initialState: AuthFeature.State(),
            reducer: { AuthFeature() }
        )
        store.exhaustivity = .off

        await store.send(.emailLoginButtonTapped) {
            $0.path[id: 0] = .emailLogin(EmailLoginFeature.State())
        }
    }

    @Test func appleLoginFailed_userCancelled_noAlert() async {
        let store = TestStore(
            initialState: AuthFeature.State(isAppleLoginLoading: true),
            reducer: { AuthFeature() }
        )

        await store.send(.appleLoginFailed(userCancelled: true)) {
            $0.isAppleLoginLoading = false
        }
    }

    @Test func appleLoginFailed_notCancelled_showsAlert() async {
        let store = TestStore(
            initialState: AuthFeature.State(isAppleLoginLoading: true),
            reducer: { AuthFeature() }
        )

        await store.send(.appleLoginFailed(userCancelled: false)) {
            $0.isAppleLoginLoading = false
            $0.alert = .showErrorMsg()
        }
    }

    @Test func googleLoginFailed_userCancelled_noAlert() async {
        let store = TestStore(
            initialState: AuthFeature.State(isGoogleLoginLoading: true),
            reducer: { AuthFeature() }
        )

        await store.send(.googleLoginFailed(userCancelled: true)) {
            $0.isGoogleLoginLoading = false
        }
    }

    @Test func googleLoginFailed_notCancelled_showsAlert() async {
        let store = TestStore(
            initialState: AuthFeature.State(isGoogleLoginLoading: true),
            reducer: { AuthFeature() }
        )

        await store.send(.googleLoginFailed(userCancelled: false)) {
            $0.isGoogleLoginLoading = false
            $0.alert = .showErrorMsg()
        }
    }

    @Test func emailLoginDelegate_signin_delegatesLogin() async {
        var state = AuthFeature.State()
        state.path.append(.emailLogin(EmailLoginFeature.State()))

        let store = TestStore(
            initialState: state,
            reducer: { AuthFeature() }
        )
        store.exhaustivity = .off

        await store.send(.path(.element(id: 0, action: .emailLogin(.delegate(.signin)))))
        await store.receive(\.delegate)
    }

    @Test func emailLoginDelegate_signupRequested_appendsSignup() async {
        var state = AuthFeature.State()
        state.path.append(.emailLogin(EmailLoginFeature.State()))

        let store = TestStore(
            initialState: state,
            reducer: { AuthFeature() }
        )
        store.exhaustivity = .off

        await store.send(.path(.element(id: 0, action: .emailLogin(.delegate(.signupRequested))))) {
            $0.path[id: 1] = .signup(SignupFeature.State())
        }
    }
}
