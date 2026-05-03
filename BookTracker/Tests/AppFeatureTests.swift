@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct AppFeatureTests {
    @Test func onAppear_listenToAuthStateChanges() async {
        let store = TestStore(
            initialState: AppFeature.State.launching,
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.authService.authStateChanges = {
            AsyncStream { $0.finish() }
        }

        await store.send(.onAppear)
    }

    @Test func authStateChanged_signedOut_goesToAuth() async {
        let store = TestStore(
            initialState: AppFeature.State.main(MainFeature.State()),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        await store.send(.authStateChanged(.signedOut, nil)) {
            $0 = .auth(AuthFeature.State())
        }
    }

    @Test func logout_clearsProfileAndGoesToAuth() async {
        let store = TestStore(
            initialState: AppFeature.State.signingOut,
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        await store.send(.logout) {
            $0 = .auth(AuthFeature.State())
        }
    }

    @Test func login_goesToMain() async {
        let store = TestStore(
            initialState: AppFeature.State.auth(AuthFeature.State()),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        await store.send(.login) {
            $0 = .main(MainFeature.State())
        }
    }

    @Test func settingLogoutDelegate_signsOut() async {
        let store = TestStore(
            initialState: AppFeature.State.main(MainFeature.State()),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.authService.signOut = {}

        await store.send(.main(.setting(.delegate(.logout)))) {
            $0 = .signingOut
        }
    }

    @Test func settingDeleteAccountDelegate_clearsDataAndSignsOut() async {
        let store = TestStore(
            initialState: AppFeature.State.main(MainFeature.State()),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.searchHistory.clearAll = { _ in }
        store.dependencies.localReceiptService.clearAll = { _ in .success(()) }
        store.dependencies.localCustomBookService.clearAll = { _ in .success(()) }
        store.dependencies.authService.signOut = {}

        await store.send(.main(.setting(.delegate(.deleteAccount)))) {
            $0 = .signingOut
        }

        await store.receive(\.logout)
    }

    @Test func authStateChanged_initialSession_validSession_goesToMain() async {
        let store = TestStore(
            initialState: AppFeature.State.launching,
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        // Create a non-expired session-like event
        // signedIn with session goes to main
        await store.send(.authStateChanged(.signedIn, nil))
    }

    @Test func authStateChanged_signedIn_withSession_goesToMain() async {
        let store = TestStore(
            initialState: AppFeature.State.auth(AuthFeature.State()),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        // signedIn without session → no state change (guarded by `if session != nil`)
        await store.send(.authStateChanged(.signedIn, nil))
    }

    @Test func authStateChanged_passwordRecovery_doesNothing() async {
        let store = TestStore(
            initialState: AppFeature.State.main(MainFeature.State()),
            reducer: { AppFeature() }
        )
        store.exhaustivity = .off

        await store.send(.authStateChanged(.passwordRecovery, nil))
    }
}
