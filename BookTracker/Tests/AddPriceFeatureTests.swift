@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct AddPriceFeatureTests {
    @Test func addButtonTapped_validPrice_savesAndShowsSuccess() async {
        var state = AddPriceFeature.State(externalBook: TestFixtures.externalBook)
        state.price = "15000"
        state.currencyCode = .krw

        let store = TestStore(
            initialState: state,
            reducer: { AddPriceFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.saveReceiptBook = { _, book in .success(book) }

        await store.send(.addButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.addResponse) {
            $0.isLoading = false
        }
    }

    @Test func addButtonTapped_invalidPrice_showsErrorAlert() async {
        var state = AddPriceFeature.State(externalBook: TestFixtures.externalBook)
        state.price = ""

        let store = TestStore(
            initialState: state,
            reducer: { AddPriceFeature() }
        )
        store.exhaustivity = .off

        await store.send(.addButtonTapped)
    }

    @Test func addButtonTapped_zeroPrice_showsErrorAlert() async {
        var state = AddPriceFeature.State(externalBook: TestFixtures.externalBook)
        state.price = "0"

        let store = TestStore(
            initialState: state,
            reducer: { AddPriceFeature() }
        )
        store.exhaustivity = .off

        await store.send(.addButtonTapped)
    }

    @Test func addResponse_failure_showsErrorAlert() async {
        var state = AddPriceFeature.State(externalBook: TestFixtures.externalBook)
        state.price = "10000"
        state.currencyCode = .krw

        let store = TestStore(
            initialState: state,
            reducer: { AddPriceFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.saveReceiptBook = { _, _ in .failure(.unknown) }

        await store.send(.addButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.addResponse) {
            $0.isLoading = false
        }
    }

    @Test func confirmAdded_delegatesAddBookToReceipt() async {
        var state = AddPriceFeature.State(externalBook: TestFixtures.externalBook)
        state.alert = .showAddSuccessAlert(book: TestFixtures.receiptBook)

        let store = TestStore(
            initialState: state,
            reducer: { AddPriceFeature() }
        )
        store.exhaustivity = .off

        await store.send(.alert(.presented(.confirmAdded(receiptBook: TestFixtures.receiptBook)))) {
            $0.alert = nil
        }
        await store.receive(\.delegate)
    }
}
