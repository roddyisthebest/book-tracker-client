@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct ResetDataFeatureTests {
    @Test func deleteAppDataTapped_showsConfirmAlert() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(),
            reducer: { ResetDataFeature() }
        )

        await store.send(.deleteAppDataTapped) {
            $0.alert = .confirmDeleteAppData()
        }
    }

    @Test func deleteServerDataTapped_showsConfirmAlert() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(),
            reducer: { ResetDataFeature() }
        )

        await store.send(.deleteServerDataTapped) {
            $0.alert = .confirmDeleteServerData()
        }
    }

    @Test func confirmDeleteAppData_success_delegatesAndShowsSuccessAlert() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(),
            reducer: { ResetDataFeature() }
        )

        store.dependencies.searchHistory.clearAll = { _ in }
        store.dependencies.localReceiptService.clearAll = { _ in .success(()) }
        store.dependencies.localCustomBookService.clearAll = { _ in .success(()) }

        await store.send(.confirmDeleteAppData) {
            $0.isAppDataDeleting = true
        }

        await store.receive(\.deleteAppDataResponse) {
            $0.isAppDataDeleting = false
            $0.alert = .appDataDeleteSuccess()
        }

        await store.receive(\.delegate)
    }

    @Test func confirmDeleteAppData_failure_showsErrorAlert() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(),
            reducer: { ResetDataFeature() }
        )

        store.dependencies.searchHistory.clearAll = { _ in }
        store.dependencies.localReceiptService.clearAll = { _ in .failure(.unknown) }
        store.dependencies.localCustomBookService.clearAll = { _ in .success(()) }

        await store.send(.confirmDeleteAppData) {
            $0.isAppDataDeleting = true
        }

        await store.receive(\.deleteAppDataResponse) {
            $0.isAppDataDeleting = false
            $0.alert = .appDataDeleteFailed()
        }
    }

    @Test func confirmDeleteServerData_success_delegatesAndShowsSuccessAlert() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(),
            reducer: { ResetDataFeature() }
        )

        store.dependencies.authService.deleteMyAppData = { .success(true) }

        await store.send(.confirmDeleteServerData) {
            $0.isServerDataDeleting = true
        }

        await store.receive(\.deleteServerDataResponse) {
            $0.isServerDataDeleting = false
            $0.alert = .serverDataDeleteSuccess()
        }

        await store.receive(\.delegate)
    }

    @Test func confirmDeleteServerData_failure_showsErrorAlert() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(),
            reducer: { ResetDataFeature() }
        )

        store.dependencies.authService.deleteMyAppData = {
            .failure(.unknown(message: "fail"))
        }

        await store.send(.confirmDeleteServerData) {
            $0.isServerDataDeleting = true
        }

        await store.receive(\.deleteServerDataResponse) {
            $0.isServerDataDeleting = false
            $0.alert = .serverDataDeleteFailed()
        }
    }

    @Test func alertConfirmDeleteServerData_triggersConfirmAction() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(
                alert: .confirmDeleteServerData()
            ),
            reducer: { ResetDataFeature() }
        )

        store.dependencies.authService.deleteMyAppData = { .success(true) }

        await store.send(.alert(.presented(.confirmDeleteServerData))) {
            $0.alert = nil
        }

        await store.receive(\.confirmDeleteServerData) {
            $0.isServerDataDeleting = true
        }

        await store.receive(\.deleteServerDataResponse) {
            $0.isServerDataDeleting = false
            $0.alert = .serverDataDeleteSuccess()
        }

        await store.receive(\.delegate)
    }

    @Test func alertConfirmDeleteAppData_triggersConfirmAction() async {
        let store = TestStore(
            initialState: ResetDataFeature.State(
                alert: .confirmDeleteAppData()
            ),
            reducer: { ResetDataFeature() }
        )

        store.dependencies.searchHistory.clearAll = { _ in }
        store.dependencies.localReceiptService.clearAll = { _ in .success(()) }
        store.dependencies.localCustomBookService.clearAll = { _ in .success(()) }

        await store.send(.alert(.presented(.confirmDeleteAppData))) {
            $0.alert = nil
        }

        await store.receive(\.confirmDeleteAppData) {
            $0.isAppDataDeleting = true
        }

        await store.receive(\.deleteAppDataResponse) {
            $0.isAppDataDeleting = false
            $0.alert = .appDataDeleteSuccess()
        }

        await store.receive(\.delegate)
    }
}
