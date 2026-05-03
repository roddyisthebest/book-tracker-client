@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct SettingFeatureTests {
    @Test func onAppear_setsVersionDisplay() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )

        store.dependencies.appInfoService.versionDisplay = { "v 1.0.0 (1)" }

        await store.send(.onAppear) {
            $0.versionDisplay = "v 1.0.0 (1)"
        }
    }

    @Test func navigateToDataManage_appendsPath() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )
        store.exhaustivity = .off

        await store.send(.navigateButtonTapped(.dataManage)) {
            $0.path[id: 0] = .dataManage(DataManageFeature.State())
        }
    }

    @Test func navigateToMyInfo_appendsPath() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )
        store.exhaustivity = .off

        await store.send(.navigateButtonTapped(.myInfo)) {
            $0.path[id: 0] = .myInfo(MyInfoFeature.State())
        }
    }

    @Test func navigateToTermsOfService_appendsPath() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )
        store.exhaustivity = .off

        await store.send(.navigateButtonTapped(.termsOfService)) {
            $0.path[id: 0] = .termsOfService
        }
    }

    @Test func openPageButtonTapped_setsSafariURL() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )

        await store.send(.openPageButtonTapped(.userGuide)) {
            $0.safariURL = SettingFeature.NotionPage.userGuide.url
        }
    }

    @Test func safariDismissed_clearsSafariURL() async {
        var initialState = SettingFeature.State()
        initialState.safariURL = URL(string: "https://example.com")

        let store = TestStore(
            initialState: initialState,
            reducer: { SettingFeature() }
        )

        await store.send(.safariDismissed) {
            $0.safariURL = nil
        }
    }

    @Test func logoutButtonTapped_showsConfirmAlert() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )

        await store.send(.logoutButtonTapped) {
            $0.alert = .confirmLogout()
        }
    }

    @Test func confirmLogout_delegatesLogout() async {
        let store = TestStore(
            initialState: SettingFeature.State(alert: .confirmLogout()),
            reducer: { SettingFeature() }
        )

        await store.send(.alert(.presented(.confirmLogout))) {
            $0.alert = nil
        }
        await store.receive(\.delegate)
    }

    @Test func deleteAccountButtonTapped_showsConfirmAlert() async {
        let store = TestStore(
            initialState: SettingFeature.State(),
            reducer: { SettingFeature() }
        )

        await store.send(.deleteAccountButtonTapped) {
            $0.alert = .confirmDeleteAccount()
        }
    }

    @Test func confirmDeleteAccount_success_delegatesDeleteAccount() async {
        let store = TestStore(
            initialState: SettingFeature.State(alert: .confirmDeleteAccount()),
            reducer: { SettingFeature() }
        )

        store.dependencies.authService.deleteAccountOnServer = { .success(()) }

        await store.send(.alert(.presented(.confirmDeleteAccount))) {
            $0.alert = nil
            $0.isDeletingAccount = true
        }

        await store.receive(\.deleteAccountSucceeded) {
            $0.isDeletingAccount = false
        }

        await store.receive(\.delegate)
    }

    @Test func confirmDeleteAccount_failure_showsFailedAlert() async {
        let store = TestStore(
            initialState: SettingFeature.State(alert: .confirmDeleteAccount()),
            reducer: { SettingFeature() }
        )

        store.dependencies.authService.deleteAccountOnServer = {
            .failure(.unknown(message: "error"))
        }

        await store.send(.alert(.presented(.confirmDeleteAccount))) {
            $0.alert = nil
            $0.isDeletingAccount = true
        }

        await store.receive(\.deleteAccountFailed) {
            $0.isDeletingAccount = false
            $0.alert = .deleteAccountFailed()
        }
    }
}
