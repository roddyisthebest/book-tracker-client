@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct BookDetailFeatureTests {
    @Test func onAppear_fetchesBook() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(id: TestFixtures.bookId),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.bookService.fetch = { _ in .success(TestFixtures.book) }

        await store.send(.onAppear)

        await store.receive(\.fetch) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.fetchResponse) {
            $0.isLoading = false
            $0.book = TestFixtures.book
        }
    }

    @Test func fetch_nilId_setsError() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(id: nil),
            reducer: { BookDetailFeature() }
        )

        await store.send(.fetch) {
            $0.isLoading = false
            $0.errorMessage = String(localized: "invalid_book_request")
        }
    }

    @Test func fetch_failure_setsErrorMessage() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(id: TestFixtures.bookId),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.bookService.fetch = { _ in
            .failure(.storage(code: "NOT_FOUND", status: 404, message: "Book not found"))
        }

        await store.send(.fetch) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.fetchResponse) {
            $0.isLoading = false
            $0.errorMessage = AppError.storage(code: "NOT_FOUND", status: 404, message: "Book not found").localizedDescription
        }
    }

    @Test func deleteButtonTapped_showsConfirmation() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(id: TestFixtures.bookId),
            reducer: { BookDetailFeature() }
        )

        await store.send(.deleteButtonTapped) {
            $0.destination = .alert(.deleteConfirmation())
        }
    }

    @Test func confirmDeletion_success_delegates() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                destination: .alert(.deleteConfirmation())
            ),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.bookService.delete = { id in .success(id) }

        await store.send(.destination(.presented(.alert(.confirmDeletion)))) {
            $0.destination = nil
            $0.isDeleting = true
        }

        await store.receive(\.deletionResponse) {
            $0.isDeleting = false
        }

        await store.receive(\.delegate)
    }

    @Test func confirmDeletion_failure_showsAlert() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                destination: .alert(.deleteConfirmation())
            ),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.bookService.delete = { _ in
            .failure(.unknown(message: "delete failed"))
        }

        await store.send(.destination(.presented(.alert(.confirmDeletion)))) {
            $0.destination = nil
            $0.isDeleting = true
        }

        await store.receive(\.deletionResponse) {
            $0.isDeleting = false
            $0.destination = .alert(.showDeletionErrorAlert())
        }
    }

    @Test func updateButtonTapped_withBook_showsForm() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                book: TestFixtures.book
            ),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.date = .constant(fixedDate)

        await store.send(.updateButtonTapped) {
            $0.destination = .formBook(
                BookFormFeature.State(
                    externalId: "ext-001",
                    bookId: TestFixtures.bookId,
                    book: TestFixtures.book,
                    changeMode: nil,
                    now: fixedDate
                )
            )
        }
    }

    @Test func updateButtonTapped_noBook_showsAlert() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(id: TestFixtures.bookId),
            reducer: { BookDetailFeature() }
        )

        await store.send(.updateButtonTapped) {
            $0.destination = .alert(.showUpdateAccessDeniedAlert())
        }
    }

    @Test func changeStatusButtonTapped_withBook_showsFormWithChangeMode() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                book: TestFixtures.book
            ),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.date = .constant(fixedDate)

        await store.send(.changeStatusButtonTapped(.done)) {
            $0.destination = .formBook(
                BookFormFeature.State(
                    externalId: "ext-001",
                    bookId: TestFixtures.bookId,
                    book: TestFixtures.book,
                    changeMode: .done,
                    now: fixedDate
                )
            )
        }
    }

    @Test func viewDetailButtonTapped_withExternalId_showsBookInfo() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                book: TestFixtures.book
            ),
            reducer: { BookDetailFeature() }
        )

        await store.send(.viewDetailButtonTapped) {
            $0.destination = .bookInfo(BookInfoFeature.State(externalBookId: "ext-001"))
        }
    }

    @Test func formDelegate_confirmUpdate_updatesBook() async {
        let updatedBook = TestFixtures.doneBook

        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                book: TestFixtures.book,
                destination: .formBook(
                    BookFormFeature.State(
                        externalId: "ext-001",
                        bookId: TestFixtures.bookId,
                        book: TestFixtures.book,
                        changeMode: nil
                    )
                )
            ),
            reducer: { BookDetailFeature() }
        )

        await store.send(.destination(.presented(.formBook(.delegate(.confirmUpdate(updatedBook)))))) {
            $0.destination = nil
            $0.book = updatedBook
        }
    }

    @Test func retryFetch_triggersNewFetch() async {
        let store = TestStore(
            initialState: BookDetailFeature.State(
                id: TestFixtures.bookId,
                destination: .alert(.showDeletionErrorAlert())
            ),
            reducer: { BookDetailFeature() }
        )

        store.dependencies.bookService.fetch = { _ in .success(TestFixtures.book) }

        await store.send(.destination(.presented(.alert(.retryFetch)))) {
            $0.destination = nil
        }

        await store.receive(\.fetch) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.fetchResponse) {
            $0.isLoading = false
            $0.book = TestFixtures.book
        }
    }
}
