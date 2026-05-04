@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ReceiptListFeatureTests {
    @Test func onAppear_loadsReceipts() async {
        let store = TestStore(
            initialState: ReceiptListFeature.State(),
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceipts = { _, _, _ in .success([TestFixtures.receiptSummary]) }

        await store.send(.onAppear)
        await store.receive(\.loadReceipts) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadReceiptResponse) {
            $0.loadingState = .loaded
            $0.list = [TestFixtures.receiptSummary]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func loadReceipts_failure_setsError() async {
        let store = TestStore(
            initialState: ReceiptListFeature.State(),
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceipts = { _, _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadReceipts) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadReceiptResponse) {
            $0.loadingState = .loaded
            $0.list = []
            $0.loadingState = .error
            $0.nextIndex = 0
            $0.hasMore = false
        }
    }

    @Test func loadMore_success_appendsReceipts() async {
        var state = ReceiptListFeature.State()
        state.list = [TestFixtures.receiptSummary]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        let second = ReceiptSummary(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000042")!,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            receiptAt: Date(timeIntervalSince1970: 1_700_000_000),
            source: "google_books",
            totalMicros: 10_000_000_000,
            totalUsdMicros: 7_000_000,
            type: .rental,
            firstBookTitle: "Second Book",
            totalQuantity: 1,
            sourceCurrencyCode: .krw
        )

        store.dependencies.receiptService.loadReceipts = { _, _, _ in .success([second]) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.list = [TestFixtures.receiptSummary, second]
            $0.nextIndex = 2
            $0.hasMore = false
        }
    }

    @Test func loadMore_guardPreventsDoubleLoad() async {
        var state = ReceiptListFeature.State()
        state.isLoadingMore = true

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptListFeature() }
        )

        await store.send(.loadMore)
    }

    @Test func loadMore_failure_showsAlert() async {
        var state = ReceiptListFeature.State()
        state.list = [TestFixtures.receiptSummary]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceipts = { _, _, _ in .failure(.unknown(message: "load fail")) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
        }
    }

    @Test func receiptCardTapped_presentsDetail() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptListFeature.State(),
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        await store.send(.recepitCardTapped(.purchase, id)) {
            $0.receiptDetail = ReceiptDetailFeature.State(id: id)
        }
    }

    @Test func deleteButtonTapped_showsConfirmAlert() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: ReceiptListFeature.State(),
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteButtonTapped(id))
    }

    @Test func confirmDeletion_success_reloads() async {
        let id = TestFixtures.receiptSummary.id

        var state = ReceiptListFeature.State()
        state.alert = .deleteConfirmation(id: id)

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.deleteReceipt = { _ in .success(id) }
        store.dependencies.receiptService.loadReceipts = { _, _, _ in .success([]) }

        await store.send(.alert(.presented(.confirmDeletion(id: id)))) {
            $0.isDeleting = true
        }

        await store.receive(\.deleteReceiptResponse) {
            $0.isDeleting = false
        }

        await store.receive(\.loadReceipts)
    }

    @Test func confirmDeletion_failure_showsAlert() async {
        let id = TestFixtures.receiptSummary.id

        var state = ReceiptListFeature.State()
        state.alert = .deleteConfirmation(id: id)

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.deleteReceipt = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.alert(.presented(.confirmDeletion(id: id)))) {
            $0.isDeleting = true
        }

        await store.receive(\.deleteReceiptResponse) {
            $0.isDeleting = false
            $0.alert = .deleteFailed()
        }
    }

    @Test func onRefresh_reloads() async {
        let store = TestStore(
            initialState: ReceiptListFeature.State(),
            reducer: { ReceiptListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.loadReceipts = { _, _, _ in .success([]) }

        await store.send(.onRefresh)
        await store.receive(\.loadReceipts)
    }
}
