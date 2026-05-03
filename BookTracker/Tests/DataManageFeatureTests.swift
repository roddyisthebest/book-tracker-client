@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct DataManageFeatureTests {
    @Test func csvExportButtonTapped_success_presentsShare() async {
        let store = TestStore(
            initialState: DataManageFeature.State(),
            reducer: { DataManageFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .success([TestFixtures.book]) }

        await store.send(.csvExportButtonTapped) {
            $0.isExporting = true
            $0.exportFilePath = nil
        }

        await store.receive(\.csvExportResponse) {
            $0.isExporting = false
            $0.isSharePresented = true
        }
    }

    @Test func csvExportButtonTapped_failure_stopsExporting() async {
        let store = TestStore(
            initialState: DataManageFeature.State(),
            reducer: { DataManageFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.csvExportButtonTapped) {
            $0.isExporting = true
        }

        await store.receive(\.csvExportResponse) {
            $0.isExporting = false
        }
    }

    @Test func shareDismissed_hidesShare() async {
        var state = DataManageFeature.State()
        state.isSharePresented = true

        let store = TestStore(
            initialState: state,
            reducer: { DataManageFeature() }
        )

        await store.send(.shareDismissed) {
            $0.isSharePresented = false
        }
    }

    @Test func dataResetButtonTapped_returnsNone() async {
        let store = TestStore(
            initialState: DataManageFeature.State(),
            reducer: { DataManageFeature() }
        )

        await store.send(.dataResetButtonTapped)
    }
}
