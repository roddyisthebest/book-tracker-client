@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct CollectionDetailFeatureTests {
    @Test func onAppear_loadsBooks() async {
        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: TestFixtures.collectionSummary),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .success([TestFixtures.book]) }

        await store.send(.onAppear)
        await store.receive(\.loadBooks) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadBooksResponse) {
            $0.loadingState = .loaded
            $0.books = [TestFixtures.book]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func loadBooks_failure_setsError() async {
        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: TestFixtures.collectionSummary),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .failure(.unknown(message: "fail")) }

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
        var state = CollectionDetailFeature.State(collection: TestFixtures.collectionSummary)
        state.books = [TestFixtures.book]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .success([TestFixtures.doneBook]) }

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

    @Test func loadMore_failure_showsAlert() async {
        var state = CollectionDetailFeature.State(collection: TestFixtures.collectionSummary)
        state.books = [TestFixtures.book]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.destination = .alert(.showInfiniteFetchingErrorMessage())
        }
    }

    @Test func deleteButtonTapped_customCollection_showsAlert() async {
        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: TestFixtures.collectionSummary),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteButtonTapped) {
            $0.destination = .alert(.deleteConfirmation())
        }
    }

    @Test func deleteButtonTapped_nonCustomCollection_noOp() async {
        let nonCustom = UserCollectionSummary(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000052")!,
            userId: TestFixtures.userId,
            name: "Purchase",
            type: .purchase,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            description: "",
            previewBooks: []
        )

        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: nonCustom),
            reducer: { CollectionDetailFeature() }
        )

        await store.send(.deleteButtonTapped)
    }

    @Test func confirmDeletion_success_delegatesDelete() async {
        let id = TestFixtures.collectionSummary.id

        let store = TestStore(
            initialState: CollectionDetailFeature.State(
                collection: TestFixtures.collectionSummary,
                destination: .alert(.deleteConfirmation())
            ),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.delete = { _ in .success(id) }

        await store.send(.destination(.presented(.alert(.confirmDeletion)))) {
            $0.isDeleting = true
        }

        await store.receive(\.deletionResponse) {
            $0.isDeleting = false
        }

        await store.receive(\.delegate)
    }

    @Test func confirmDeletion_failure_showsErrorAlert() async {
        let store = TestStore(
            initialState: CollectionDetailFeature.State(
                collection: TestFixtures.collectionSummary,
                destination: .alert(.deleteConfirmation())
            ),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.delete = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.destination(.presented(.alert(.confirmDeletion)))) {
            $0.isDeleting = true
        }

        await store.receive(\.deletionResponse) {
            $0.isDeleting = false
            $0.destination = .alert(.showDeletionFailedAlert())
        }
    }

    @Test func editButtonTapped_books_presentsSelectBooks() async {
        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: TestFixtures.collectionSummary),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        await store.send(.editButtonTapped(.books)) {
            $0.destination = .selectBooks(CollectionSelectBooksFeature.State(collection: TestFixtures.collectionSummary.toUserCollection()))
        }
    }

    @Test func editButtonTapped_collection_nonCustom_noOp() async {
        let nonCustom = UserCollectionSummary(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000052")!,
            userId: TestFixtures.userId,
            name: "Purchase",
            type: .purchase,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            description: "",
            previewBooks: []
        )

        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: nonCustom),
            reducer: { CollectionDetailFeature() }
        )

        await store.send(.editButtonTapped(.collection))
    }

    @Test func bookCardTapped_presentsBookDetail() async {
        var state = CollectionDetailFeature.State(collection: TestFixtures.collectionSummary)
        state.books = [TestFixtures.book]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionDetailFeature() }
        )

        await store.send(.bookCardTapped(TestFixtures.bookId)) {
            $0.destination = .viewBookDetail(BookDetailFeature.State(id: TestFixtures.bookId))
        }
    }

    @Test func bookDetail_deletion_reloadsBooks() async {
        var state = CollectionDetailFeature.State(collection: TestFixtures.collectionSummary)
        state.books = [TestFixtures.book]
        state.destination = .viewBookDetail(BookDetailFeature.State(id: TestFixtures.bookId))

        let store = TestStore(
            initialState: state,
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .success([]) }

        await store.send(.destination(.presented(.viewBookDetail(.delegate(.confirmDeletion(deleted: TestFixtures.bookId)))))) {
            $0.destination = nil
        }

        await store.receive(\.loadBooks)
    }

    @Test func bookDetail_update_reloadsBooks() async {
        var bookDetailState = BookDetailFeature.State(id: TestFixtures.bookId)
        bookDetailState.destination = .formBook(BookFormFeature.State(
            externalId: "ext-001",
            bookId: TestFixtures.bookId,
            book: TestFixtures.book,
            changeMode: nil
        ))

        var state = CollectionDetailFeature.State(collection: TestFixtures.collectionSummary)
        state.books = [TestFixtures.book]
        state.destination = .viewBookDetail(bookDetailState)

        let store = TestStore(
            initialState: state,
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .success([TestFixtures.book]) }

        await store.send(.destination(.presented(.viewBookDetail(.destination(.presented(.formBook(.delegate(.confirmUpdate(TestFixtures.book)))))))))

        await store.receive(\.loadBooks)
    }

    @Test func onRefresh_reloadsBooks() async {
        let store = TestStore(
            initialState: CollectionDetailFeature.State(collection: TestFixtures.collectionSummary),
            reducer: { CollectionDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listBooks = { _, _, _ in .success([]) }

        await store.send(.onRefresh)
        await store.receive(\.onAppear)
        await store.receive(\.loadBooks)
    }
}
