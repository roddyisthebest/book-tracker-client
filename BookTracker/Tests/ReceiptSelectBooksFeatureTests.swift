@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct ReceiptSelectBooksFeatureTests {
    @Test func onAppear_loadsBooks() async {
        let store = TestStore(
            initialState: ReceiptSelectBooksFeature.State(type: .purchase),
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.fetchBooks = { _, _ in .success([TestFixtures.receiptBook]) }

        await store.send(.onAppear)
        await store.receive(\.loadBooks) {
            $0.isFetching = true
            $0.isError = false
        }

        await store.receive(\.loadBooksResponse) {
            $0.isFetching = false
            $0.books = [TestFixtures.receiptBook]
        }
    }

    @Test func loadBooksResponse_success_setsBooks() async {
        let store = TestStore(
            initialState: ReceiptSelectBooksFeature.State(type: .purchase),
            reducer: { ReceiptSelectBooksFeature() }
        )

        await store.send(.loadBooksResponse(.success([TestFixtures.receiptBook]))) {
            $0.isFetching = false
            $0.books = [TestFixtures.receiptBook]
        }
    }

    @Test func loadBooksResponse_failure_setsError() async {
        let store = TestStore(
            initialState: ReceiptSelectBooksFeature.State(type: .purchase),
            reducer: { ReceiptSelectBooksFeature() }
        )

        await store.send(.loadBooksResponse(.failure(.unknown))) {
            $0.isFetching = false
            $0.isError = true
        }
    }

    @Test func deleteButtonTapped_deletesBook() async {
        var state = ReceiptSelectBooksFeature.State(type: .purchase)
        state.books = [TestFixtures.receiptBook]

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.remove = { _, id, _ in .success(id) }

        await store.send(.deleteButtonTapped(id: TestFixtures.receiptBook.id)) {
            $0.isDeleting = true
        }

        await store.receive(\.deleteBookResponse) {
            $0.isDeleting = false
            $0.books = []
        }

        await store.receive(\.delegate)
    }

    @Test func deleteBookResponse_success_removesBookAndDelegates() async {
        var state = ReceiptSelectBooksFeature.State(type: .purchase)
        state.books = [TestFixtures.receiptBook]

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteBookResponse(.success(TestFixtures.receiptBook.id))) {
            $0.isDeleting = false
            $0.books = []
        }

        await store.receive(\.delegate)
    }

    @Test func deleteBookResponse_failure_showsAlert() async {
        var state = ReceiptSelectBooksFeature.State(type: .purchase)
        state.books = [TestFixtures.receiptBook]

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteBookResponse(.failure(.unknown))) {
            $0.isDeleting = false
        }
    }

    @Test func addButtonTapped_showsSearch() async {
        let store = TestStore(
            initialState: ReceiptSelectBooksFeature.State(type: .purchase),
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.addButtonTapped) {
            $0.destination = .search(SearchFeature.State())
        }
    }

    @Test func issueButtonTapped_showsIssueReceipt() async {
        var state = ReceiptSelectBooksFeature.State(type: .purchase)
        state.books = [TestFixtures.receiptBook]

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.issueButtonTapped)
    }

    @Test func onRefresh_sendsOnAppear() async {
        let store = TestStore(
            initialState: ReceiptSelectBooksFeature.State(type: .purchase),
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.fetchBooks = { _, _ in .success([]) }

        await store.send(.onRefresh)
        await store.receive(\.onAppear)
        await store.receive(\.loadBooks)
    }

    @Test func issueReceiptDelegate_completed_clearsBooksAndDelegates() async {
        var state = ReceiptSelectBooksFeature.State(type: .purchase)
        state.books = [TestFixtures.receiptBook]
        state.destination = .issueReceipt(IssueReceiptFeature.State(receiptBooks: [TestFixtures.receiptBook], type: .purchase))

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.issueReceipt(.delegate(.issueReceiptCompleted))))) {
            $0.destination = nil
            $0.books = []
        }

        await store.receive(\.delegate)
    }

    @Test func searchDelegate_addBookToReceipt_appendsBook() async {
        var state = ReceiptSelectBooksFeature.State(type: .purchase)
        state.destination = .search(SearchFeature.State(
            detailSheet: ExternalBookDetailFeature.State(id: "ext-001", book: TestFixtures.externalBook)
        ))

        let store = TestStore(
            initialState: state,
            reducer: { ReceiptSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.search(.detailSheet(.presented(.delegate(.addBookToReceipt(receiptBook: TestFixtures.receiptBook, type: .purchase)))))))) {
            $0.books = [TestFixtures.receiptBook]
        }
    }
}
