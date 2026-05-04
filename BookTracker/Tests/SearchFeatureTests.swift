@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct SearchFeatureTests {
    @Test func queryInput_switchesSuggestionsToResults() async {
        let store = TestStore(
            initialState: SearchFeature.State(),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off
        store.dependencies.continuousClock = TestClock()

        await store.send(.binding(.set(\.query, "swift"))) {
            $0.query = "swift"
            $0.destination = .results(SearchResultFeature.State(keyword: "swift"))
        }

        await store.receive(\.destination)
    }

    @Test func queryCleared_switchesResultsToSuggestions() async {
        var initialState = SearchFeature.State()
        initialState.query = "swift"
        initialState.destination = .results(SearchResultFeature.State(keyword: "swift"))

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        await store.send(.binding(.set(\.query, ""))) {
            $0.query = ""
            $0.destination = .suggestions(SearchSuggestionsFeature.State())
        }
    }

    @Test func queryResetButtonTapped_resetsToSuggestions() async {
        var initialState = SearchFeature.State()
        initialState.query = "swift"
        initialState.destination = .results(SearchResultFeature.State(keyword: "swift"))

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        await store.send(.queryResetButtonTapped) {
            $0.query = ""
            $0.destination = .suggestions(SearchSuggestionsFeature.State())
        }
    }

    @Test func suggestionDelegate_setKeyword_switchesToResults() async {
        let store = TestStore(
            initialState: SearchFeature.State(),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off
        store.dependencies.continuousClock = TestClock()

        await store.send(.destination(.presented(.suggestions(.delegate(.setKeyword("swift")))))) {
            $0.query = "swift"
            $0.destination = .results(SearchResultFeature.State(keyword: "swift"))
        }

        await store.receive(\.destination)
    }

    @Test func resultDelegate_tapBook_presentsDetailSheet() async {
        var initialState = SearchFeature.State()
        initialState.destination = .results(SearchResultFeature.State())

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.results(.delegate(.tapBook(id: "ext-001")))))) {
            $0.detailSheet = ExternalBookDetailFeature.State(id: "ext-001")
        }
    }

    @Test func suggestionsDelegate_addCustomBook_presentsForm() async {
        let store = TestStore(
            initialState: SearchFeature.State(),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.suggestions(.delegate(.addCustomBook))))) {
            $0.customBookForm = CustomBookFormFeature.State()
        }
    }

    @Test func suggestionsDelegate_openCustomBookList_presentsList() async {
        let store = TestStore(
            initialState: SearchFeature.State(),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.suggestions(.delegate(.openCustomBookList))))) {
            $0.customBookList = CustomBookListFeature.State()
        }
    }

    @Test func customBookListDelegate_openBook_presentsDetailSheet() async {
        let store = TestStore(
            initialState: SearchFeature.State(
                customBookList: CustomBookListFeature.State()
            ),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        await store.send(.customBookList(.presented(.delegate(.openBook(TestFixtures.externalBook))))) {
            $0.customBookList = nil
            $0.detailSheet = ExternalBookDetailFeature.State(id: TestFixtures.externalBook.id, book: TestFixtures.externalBook)
        }
    }

    @Test func customBookFormDelegate_didCreate_savesAndPresentsDetail() async {
        let store = TestStore(
            initialState: SearchFeature.State(
                customBookForm: CustomBookFormFeature.State()
            ),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localCustomBookService.save = { book, _ in .success(book) }

        await store.send(.customBookForm(.presented(.delegate(.didCreate(TestFixtures.externalBook))))) {
            $0.customBookForm = nil
            $0.detailSheet = ExternalBookDetailFeature.State(id: TestFixtures.externalBook.id, book: TestFixtures.externalBook)
        }
    }

    @Test func detailSheet_confirmCreation_removesCustomBook() async {
        let book = Book(
            id: UUID(),
            userId: TestFixtures.userId,
            externalBookId: "custom_123",
            title: "Test",
            author: "Author",
            publisher: "",
            pageCount: 100,
            pageCountEditable: false,
            imageUrl: nil,
            isbn: "",
            status: .reading,
            type: .paper,
            startedAt: Date(),
            readCount: nil,
            memo: nil,
            endedAt: nil,
            score: nil,
            review: nil,
            droppedReason: nil
        )

        let store = TestStore(
            initialState: SearchFeature.State(
                detailSheet: ExternalBookDetailFeature.State(
                    id: "custom_123",
                    book: TestFixtures.externalBook,
                    destination: .formBook(BookFormFeature.State(externalId: "custom_123", externalBook: TestFixtures.externalBook, now: Date()))
                )
            ),
            reducer: { SearchFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localCustomBookService.remove = { id, _ in .success(id) }

        await store.send(.detailSheet(.presented(.destination(.presented(.formBook(.delegate(.confirmCreation(book)))))))) {
            $0.detailSheet = nil
        }
    }
}
