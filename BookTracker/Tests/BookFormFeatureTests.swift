@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct BookFormFeatureTests {
    // MARK: - Create

    @Test func addButtonTapped_creationSuccess_showsAlert() async {
        let createdBook = TestFixtures.book

        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-001",
                externalBook: TestFixtures.externalBook
            ),
            reducer: { BookFormFeature() }
        )

        store.dependencies.bookService.create = { _ in .success(createdBook) }

        await store.send(.addButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.creationResponse) {
            $0.isLoading = false
            $0.destination = .alert(.showCreationMessage(new: createdBook))
        }
    }

    @Test func addButtonTapped_creationFailure_showsErrorAlert() async {
        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-001",
                externalBook: TestFixtures.externalBook
            ),
            reducer: { BookFormFeature() }
        )

        store.dependencies.bookService.create = { _ in
            .failure(.storage(code: "ERR", status: 500, message: "Server error"))
        }

        await store.send(.addButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.creationResponse) {
            $0.isLoading = false
            $0.destination = .alert(.showErrorMessage(message: "Server error"))
        }
    }

    // MARK: - Update

    @Test func saveButtonTapped_updateSuccess_showsAlert() async {
        let updatedBook = TestFixtures.doneBook

        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-002",
                bookId: TestFixtures.doneBook.id,
                book: TestFixtures.doneBook,
                changeMode: nil
            ),
            reducer: { BookFormFeature() }
        )

        store.dependencies.bookService.update = { _, _ in .success(updatedBook) }

        await store.send(.saveButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.updateResponse) {
            $0.isLoading = false
            $0.destination = .alert(.showUpdateMessage(updated: updatedBook))
        }
    }

    @Test func saveButtonTapped_noBookId_doesNothing() async {
        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-001",
                externalBook: TestFixtures.externalBook
            ),
            reducer: { BookFormFeature() }
        )

        // bookId is nil for create mode, saveButtonTapped should do nothing
        await store.send(.saveButtonTapped)
    }

    @Test func saveButtonTapped_updateFailure_showsErrorAlert() async {
        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-002",
                bookId: TestFixtures.doneBook.id,
                book: TestFixtures.doneBook,
                changeMode: nil
            ),
            reducer: { BookFormFeature() }
        )

        store.dependencies.bookService.update = { _, _ in
            .failure(.storage(code: "ERR", status: 500, message: "Update failed"))
        }

        await store.send(.saveButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.updateResponse) {
            $0.isLoading = false
            $0.destination = .alert(.showErrorMessage(message: "Update failed"))
        }
    }

    // MARK: - Alert Delegates

    @Test func confirmCreationAlert_delegatesConfirmCreation() async {
        let book = TestFixtures.book

        let store = TestStore(
            initialState: {
                var state = BookFormFeature.State(
                    externalId: "ext-001",
                    externalBook: TestFixtures.externalBook
                )
                state.destination = .alert(.showCreationMessage(new: book))
                return state
            }(),
            reducer: { BookFormFeature() }
        )

        await store.send(.destination(.presented(.alert(.confirmCreation(book))))) {
            $0.destination = nil
        }

        await store.receive(\.delegate)
    }

    @Test func confirmUpdateAlert_delegatesConfirmUpdate() async {
        let book = TestFixtures.doneBook

        let store = TestStore(
            initialState: {
                var state = BookFormFeature.State(
                    externalId: "ext-002",
                    bookId: book.id,
                    book: book,
                    changeMode: nil
                )
                state.destination = .alert(.showUpdateMessage(updated: book))
                return state
            }(),
            reducer: { BookFormFeature() }
        )

        await store.send(.destination(.presented(.alert(.confirmUpdate(book))))) {
            $0.destination = nil
        }

        await store.receive(\.delegate)
    }

    // MARK: - Binding Sync

    @Test func progressBinding_syncsPage() async {
        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-001",
                externalBook: TestFixtures.externalBook
            ),
            reducer: { BookFormFeature() }
        )

        // entirePage defaults to "300" from externalBook.pageCount
        await store.send(.binding(.set(\.progress, 50.0))) {
            $0.progress = 50.0
            $0.page = "150"
        }
    }

    @Test func pageBinding_syncsProgress() async {
        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-001",
                externalBook: TestFixtures.externalBook
            ),
            reducer: { BookFormFeature() }
        )

        await store.send(.binding(.set(\.page, "150"))) {
            $0.page = "150"
            $0.progress = 50.0
        }
    }

    // MARK: - Change Mode

    @Test func changeMode_preventsStatusChange() async {
        let store = TestStore(
            initialState: BookFormFeature.State(
                externalId: "ext-002",
                bookId: TestFixtures.book.id,
                book: TestFixtures.book,
                changeMode: .done
            ),
            reducer: { BookFormFeature() }
        )

        // Attempting to change status should be reverted to changeMode value
        await store.send(.binding(.set(\.status, .reading)))
    }

    // MARK: - toPatch

    @Test func toPatch_doneStatus_includesStartedAt() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let state = BookFormFeature.State(
            externalId: "ext-002",
            bookId: TestFixtures.doneBook.id,
            book: TestFixtures.doneBook,
            changeMode: nil,
            now: now
        )

        let patch = state.toPatch()
        #expect(patch.startedAt != nil)
        #expect(patch.status == .done)
        #expect(patch.endedAt != nil)
    }

    @Test func toPatch_readingStatus_includesStartedAt() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let state = BookFormFeature.State(
            externalId: "ext-001",
            bookId: TestFixtures.book.id,
            book: TestFixtures.book,
            changeMode: nil,
            now: now
        )

        let patch = state.toPatch()
        #expect(patch.startedAt != nil)
        #expect(patch.status == .reading)
        #expect(patch.readCount != nil)
    }

    @Test func toPatch_wantStatus_excludesStartedAt() {
        let wantBook = Book(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            userId: TestFixtures.userId,
            externalBookId: "ext-003",
            title: "Want Book",
            author: "Author",
            publisher: "Publisher",
            pageCount: 100,
            pageCountEditable: false,
            imageUrl: nil,
            isbn: "1234567890",
            status: .want,
            type: .paper,
            startedAt: nil,
            readCount: nil,
            memo: nil,
            endedAt: nil,
            score: nil,
            review: nil,
            droppedReason: nil
        )
        let state = BookFormFeature.State(
            externalId: "ext-003",
            bookId: wantBook.id,
            book: wantBook,
            changeMode: nil
        )

        let patch = state.toPatch()
        #expect(patch.startedAt == nil)
        #expect(patch.status == .want)
    }

    @Test func toPatch_droppedStatus_excludesStartedAt() {
        let droppedBook = Book(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            userId: TestFixtures.userId,
            externalBookId: "ext-004",
            title: "Dropped Book",
            author: "Author",
            publisher: "Publisher",
            pageCount: 100,
            pageCountEditable: false,
            imageUrl: nil,
            isbn: "1234567890",
            status: .dropped,
            type: .paper,
            startedAt: nil,
            readCount: nil,
            memo: nil,
            endedAt: nil,
            score: nil,
            review: nil,
            droppedReason: "boring"
        )
        let state = BookFormFeature.State(
            externalId: "ext-004",
            bookId: droppedBook.id,
            book: droppedBook,
            changeMode: nil
        )

        let patch = state.toPatch()
        #expect(patch.startedAt == nil)
        #expect(patch.status == .dropped)
        #expect(patch.droppedReason == "boring")
    }

    // MARK: - State Helpers

    @Test func isEditing_withBookId_returnsTrue() {
        let state = BookFormFeature.State(
            externalId: "ext-002",
            bookId: TestFixtures.doneBook.id,
            book: TestFixtures.doneBook,
            changeMode: nil
        )
        #expect(state.isEditing == true)
    }

    @Test func isEditing_withoutBookId_returnsFalse() {
        let state = BookFormFeature.State(
            externalId: "ext-001",
            externalBook: TestFixtures.externalBook
        )
        #expect(state.isEditing == false)
    }
}
