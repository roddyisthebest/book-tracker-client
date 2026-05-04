@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct MyBookListFeatureTests {
    @Test func onAppear_loadsBooksAndStatusCounts() async {
        let store = TestStore(
            initialState: MyBookListFeature.State(bookStatus: .reading),
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .success([TestFixtures.book]) }
        store.dependencies.bookService.statusCounts = { .success([.reading: 1, .done: 2]) }

        await store.send(.onAppear)

        await store.receive(\.loadStatusCounts)
        await store.receive(\.loadBooks)

        // 비동기 응답은 완료 순서가 비결정적이므로 개별 테스트에서 검증
    }

    @Test func loadBooks_success_setsBooksAndPagination() async {
        let store = TestStore(
            initialState: MyBookListFeature.State(bookStatus: .reading),
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .success([TestFixtures.book]) }

        await store.send(.loadBooks) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadBooksResponse) {
            $0.loadingState = .loaded
            $0.books = [TestFixtures.book]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func statusCountsResponse_success_setsCounts() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.isLoadingStatusCounts = true

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )

        await store.send(.statusCountsResponse(.success([.reading: 1, .done: 2]))) {
            $0.isLoadingStatusCounts = false
            $0.statusCounts = [.reading: 1, .done: 2]
        }
    }

    @Test func loadMore_failure_setsError() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.books = [TestFixtures.book]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.loadingState = .error
        }
    }

    @Test func loadBooks_failure_setsError() async {
        let store = TestStore(
            initialState: MyBookListFeature.State(bookStatus: .reading),
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadBooks) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadBooksResponse) {
            $0.loadingState = .loaded
            $0.books = []
            $0.loadingState = .error
            $0.nextIndex = 0
            $0.hasMore = false
        }
    }

    @Test func loadMore_success_appendsBooks() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.books = [TestFixtures.book]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
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

    @Test func loadMore_guardPreventsWhenAlreadyLoading() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.loadingState = .loading

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )

        await store.send(.loadMore)
        // No effects expected
    }

    @Test func loadMore_guardPreventsWhenNoMore() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.hasMore = false

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )

        await store.send(.loadMore)
    }

    @Test func bookCardTapped_presentsDetail() async {
        let store = TestStore(
            initialState: MyBookListFeature.State(bookStatus: .reading),
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        await store.send(.bookCardTapped(id: TestFixtures.bookId)) {
            $0.destination = .viewBookDetail(BookDetailFeature.State(id: TestFixtures.bookId))
        }
    }

    @Test func deleteButtonTapped_showsConfirmAlert() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.books = [TestFixtures.book]

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteButtonTapped(id: TestFixtures.bookId)) {
            $0.destination = .alert(.deleteConfirmation(id: TestFixtures.bookId))
        }
    }

    @Test func confirmDeletion_success_removesBookAndUpdatesCount() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.books = [TestFixtures.book]
        state.statusCounts = [.reading: 3, .done: 1]
        state.destination = .alert(.deleteConfirmation(id: TestFixtures.bookId))

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.delete = { _ in .success(TestFixtures.bookId) }

        await store.send(.destination(.presented(.alert(.confirmDeletion(id: TestFixtures.bookId))))) {
            $0.isDeleting = true
        }

        await store.receive(\.deletionResponse) {
            $0.isDeleting = false
            $0.books = []
            $0.statusCounts = [.reading: 2, .done: 1]
        }
    }

    @Test func confirmDeletion_failure_showsErrorAlert() async {
        var state = MyBookListFeature.State(bookStatus: .reading)
        state.books = [TestFixtures.book]
        state.destination = .alert(.deleteConfirmation(id: TestFixtures.bookId))

        let store = TestStore(
            initialState: state,
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.delete = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.destination(.presented(.alert(.confirmDeletion(id: TestFixtures.bookId))))) {
            $0.isDeleting = true
        }

        await store.receive(\.deletionResponse) {
            $0.isDeleting = false
            $0.destination = .alert(.showDeletionErrorAlert())
        }
    }

    @Test func refresh_reloadsBooks() async {
        let store = TestStore(
            initialState: MyBookListFeature.State(bookStatus: .reading),
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.list = { _, _, _, _ in .success([]) }

        await store.send(.refresh)
        await store.receive(\.loadBooks)
    }

    @Test func statusCountsResponse_failure_setsNil() async {
        let store = TestStore(
            initialState: MyBookListFeature.State(bookStatus: .reading),
            reducer: { MyBookListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.statusCounts = { .failure(.unknown(message: "fail")) }

        await store.send(.loadStatusCounts) {
            $0.isLoadingStatusCounts = true
        }

        await store.receive(\.statusCountsResponse) {
            $0.isLoadingStatusCounts = false
            $0.statusCounts = nil
        }
    }
}
