@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct CollectionSelectBooksFeatureTests {
    @Test func onAppear_loadsBooks() async {
        let store = TestStore(
            initialState: CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection),
            reducer: { CollectionSelectBooksFeature() }
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
        }
    }

    @Test func loadBooksResponse_success_setsBooks() async {
        let store = TestStore(
            initialState: CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection),
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.loadBooksResponse(.success([TestFixtures.book]))) {
            $0.loadingState = .loaded
            $0.books = [TestFixtures.book]
        }
    }

    @Test func loadBooksResponse_failure_setsError() async {
        let store = TestStore(
            initialState: CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection),
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.loadBooksResponse(.failure(.unknown(message: "fail")))) {
                        $0.loadingState = .error
        }
    }

    @Test func bookSelected_togglesSelection() async {
        var state = CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection)
        state.books = [TestFixtures.book]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.bookSelected(id: TestFixtures.bookId)) {
            $0.selectedIds = [TestFixtures.bookId]
        }

        await store.send(.bookSelected(id: TestFixtures.bookId)) {
            $0.selectedIds = []
        }
    }

    @Test func bookAllSelected_selectsAll() async {
        var state = CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection)
        state.books = [TestFixtures.book, TestFixtures.doneBook]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.bookAllSelected) {
            $0.selectedIds = Set([TestFixtures.book.id, TestFixtures.doneBook.id])
        }
    }

    @Test func bookAllDisselected_clearsAll() async {
        var state = CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection)
        state.books = [TestFixtures.book]
        state.selectedIds = [TestFixtures.bookId]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.bookAllDisselected) {
            $0.selectedIds = []
        }
    }

    @Test func deleteButtonTapped_showsAlert() async {
        var state = CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection)
        state.books = [TestFixtures.book]
        state.selectedIds = [TestFixtures.bookId]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.deleteButtonTapped)
    }

    @Test func confirmDeletion_removesSelectedBooks() async {
        var state = CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection)
        state.books = [TestFixtures.book, TestFixtures.doneBook]
        state.selectedIds = [TestFixtures.bookId]
        state.alert = AlertState {
            TextState("are_you_sure")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("delete")
            }
        }

        let store = TestStore(
            initialState: state,
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.alert(.presented(.confirmDeletion))) {
            $0.alert = nil
            $0.books = [TestFixtures.doneBook]
            $0.selectedIds = []
        }
    }

    @Test func saveButtonTapped_syncsBooks() async {
        var state = CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection)
        state.books = [TestFixtures.book]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionSelectBooksFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.syncBooks = { _, _ in .success(true) }

        await store.send(.saveButtonTapped) {
            $0.isSyncing = true
        }

        await store.receive(\.syncBooksResponse) {
            $0.isSyncing = false
        }

        await store.receive(\.delegate)
    }

    @Test func syncBooksResponse_success_delegates() async {
        let store = TestStore(
            initialState: CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection),
            reducer: { CollectionSelectBooksFeature() }
        )
        store.exhaustivity = .off

        await store.send(.syncBooksResponse(.success(true))) {
            $0.isSyncing = false
        }

        await store.receive(\.delegate)
    }

    @Test func syncBooksResponse_failure_showsAlert() async {
        let store = TestStore(
            initialState: CollectionSelectBooksFeature.State(collection: TestFixtures.userCollection),
            reducer: { CollectionSelectBooksFeature() }
        )

        await store.send(.syncBooksResponse(.failure(.unknown(message: "fail")))) {
            $0.isSyncing = false
            $0.alert = .showSyncingFailedAlert()
        }
    }
}
