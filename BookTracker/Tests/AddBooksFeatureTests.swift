@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct AddBooksFeatureTests {
    @Test func onAppear_loadsBooks() async {
        let store = TestStore(
            initialState: AddBooksFeature.State(),
            reducer: { AddBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .success([TestFixtures.book]) }

        await store.send(.onAppear)
        await store.receive(\.loadBooks) {
            $0.isLoading = true
            $0.errorMessage = nil
            $0.nextIndex = 0
            $0.hasMore = true
        }

        await store.receive(\.loadBooksResponse) {
            $0.isLoading = false
            $0.books = [TestFixtures.book]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func loadBooksResponse_success_setsBooks() async {
        let store = TestStore(
            initialState: AddBooksFeature.State(),
            reducer: { AddBooksFeature() }
        )

        await store.send(.loadBooksResponse(.success([TestFixtures.book]))) {
            $0.isLoading = false
            $0.books = [TestFixtures.book]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func loadBooksResponse_failure_setsError() async {
        let error = AppError.unknown(message: "fail")

        let store = TestStore(
            initialState: AddBooksFeature.State(),
            reducer: { AddBooksFeature() }
        )

        await store.send(.loadBooksResponse(.failure(error))) {
            $0.isLoading = false
            $0.books = []
            $0.errorMessage = error.localizedDescription
            $0.nextIndex = 0
            $0.hasMore = false
        }
    }

    @Test func loadMore_success_appendsBooks() async {
        var state = AddBooksFeature.State()
        state.books = [TestFixtures.book]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { AddBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .success([TestFixtures.doneBook]) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.books = [TestFixtures.book, TestFixtures.doneBook]
            $0.nextIndex = 2
            $0.hasMore = false
        }
    }

    @Test func loadMore_failure_setsError() async {
        var state = AddBooksFeature.State()
        state.books = [TestFixtures.book]
        state.nextIndex = 1
        state.hasMore = true

        let error = AppError.unknown(message: "fail")

        let store = TestStore(
            initialState: state,
            reducer: { AddBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .failure(error) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.errorMessage = error.localizedDescription
        }
    }

    @Test func loadMore_guardWhenLoading_doesNothing() async {
        var state = AddBooksFeature.State()
        state.isLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { AddBooksFeature() }
        )

        await store.send(.loadMore)
    }

    @Test func bookSelected_togglesSelection() async {
        var state = AddBooksFeature.State()
        state.books = [TestFixtures.book]

        let store = TestStore(
            initialState: state,
            reducer: { AddBooksFeature() }
        )

        await store.send(.bookSelected(TestFixtures.bookId)) {
            $0.selectedIds = [TestFixtures.bookId]
        }

        await store.send(.bookSelected(TestFixtures.bookId)) {
            $0.selectedIds = []
        }
    }

    @Test func addButtonTapped_delegatesSelectedBooks() async {
        var state = AddBooksFeature.State()
        state.books = [TestFixtures.book]
        state.selectedIds = [TestFixtures.bookId]

        let store = TestStore(
            initialState: state,
            reducer: { AddBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.addButtonTapped)
        await store.receive(\.delegate)
    }
}
