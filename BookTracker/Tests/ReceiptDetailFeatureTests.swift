@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct ReceiptDetailFeatureTests {
    @Test func onAppear_setsCurrencyAndLoadsReceipt() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptDetailFeature.State(id: id),
            reducer: { ReceiptDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceiptDetail = { _ in .success(TestFixtures.receiptDetail) }

        await store.send(.onAppear) {
            $0.targetCurrency = .krw
        }

        await store.receive(\.loadReceipt) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadReceiptResponse) {
            $0.loadingState = .loaded
            $0.detail = TestFixtures.receiptDetail
        }
    }

    @Test func loadReceipt_failure_setsError() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptDetailFeature.State(id: id),
            reducer: { ReceiptDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceiptDetail = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadReceipt) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadReceiptResponse) {
                        $0.loadingState = .error
        }
    }

    @Test func currencyChanged_updatesTargetCurrency() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptDetailFeature.State(id: id),
            reducer: { ReceiptDetailFeature() }
        )

        await store.send(.currencyChanged(.usd)) {
            $0.targetCurrency = .usd
        }
    }

    @Test func deleteButtonTapped_showsConfirmAlert() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptDetailFeature.State(id: id),
            reducer: { ReceiptDetailFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteButtonTapped)
    }

    @Test func confirmDeletion_success_delegatesDelete() async {
        let id = TestFixtures.receiptSummary.id

        var state = ReceiptDetailFeature.State(id: id)
        state.alert = AlertState {
            TextState("are_you_sure")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("delete")
            }
        }

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.deleteReceipt = { _ in .success(id) }

        await store.send(.alert(.presented(.confirmDeletion))) {
            $0.alert = nil
            $0.isDeleting = true
        }

        await store.receive(\.deleteResponse) {
            $0.isDeleting = false
        }

        await store.receive(\.delegate)
    }

    @Test func confirmDeletion_failure_showsErrorAlert() async {
        let id = TestFixtures.receiptSummary.id

        var state = ReceiptDetailFeature.State(id: id)
        state.alert = AlertState {
            TextState("are_you_sure")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("delete")
            }
        }

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.deleteReceipt = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.alert(.presented(.confirmDeletion))) {
            $0.alert = nil
            $0.isDeleting = true
        }

        await store.receive(\.deleteResponse) {
            $0.isDeleting = false
        }
    }

    @Test func onRefresh_reloadsReceipt() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptDetailFeature.State(id: id),
            reducer: { ReceiptDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceiptDetail = { _ in .success(TestFixtures.receiptDetail) }

        await store.send(.onRefresh)
        await store.receive(\.loadReceipt)
    }
}
