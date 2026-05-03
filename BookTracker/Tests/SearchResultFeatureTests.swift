@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct SearchResultFeatureTests {
    @Test func setKeyword_debouncesThenSearches() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: SearchResultFeature.State(),
            reducer: { SearchResultFeature() }
        )

        store.dependencies.continuousClock = clock
        store.dependencies.externalBookService.search = { _, _, _ in
            .success([TestFixtures.externalBook])
        }
        store.dependencies.searchKeywordService.record = { _ in
            .success(TestFixtures.searchKeyword)
        }

        await store.send(.setKeyword("swift")) {
            $0.keyword = "swift"
            $0.isLoading = true
            $0.isLoadingMore = false
            $0.errorMessage = nil
            $0.nextIndex = 0
            $0.hasMore = true
        }

        await clock.advance(by: .milliseconds(200))

        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.externalBooks = [TestFixtures.externalBook]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func setKeyword_emptyKeyword_resetsState() async {
        var initialState = SearchResultFeature.State()
        initialState.externalBooks = [TestFixtures.externalBook]
        initialState.keyword = "swift"
        initialState.nextIndex = 1

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        await store.send(.setKeyword("")) {
            $0.keyword = ""
            $0.isLoading = false
            $0.nextIndex = 0
            $0.isLoadingMore = false
            $0.hasMore = true
            $0.errorMessage = nil
            $0.externalBooks = []
        }
    }

    @Test func searchFailure_showsAlert() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: SearchResultFeature.State(),
            reducer: { SearchResultFeature() }
        )

        store.dependencies.continuousClock = clock
        store.dependencies.externalBookService.search = { _, _, _ in
            .failure(.invalidURL)
        }

        await store.send(.setKeyword("test")) {
            $0.keyword = "test"
            $0.isLoading = true
            $0.isLoadingMore = false
            $0.errorMessage = nil
            $0.nextIndex = 0
            $0.hasMore = true
        }

        await clock.advance(by: .milliseconds(200))

        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.errorMessage = ExternalBookService.ServiceError.invalidURL.localizedDescription
            $0.externalBooks = []
            $0.alert = AlertState {
                TextState("error_occurred")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("confirm")
                }
            } message: {
                TextState(ExternalBookService.ServiceError.invalidURL.localizedDescription)
            }
        }
    }

    @Test func loadMore_appendsBooks() async {
        let book2 = ExternalBook(id: "ext-002", title: "Second Book")

        var initialState = SearchResultFeature.State()
        initialState.keyword = "swift"
        initialState.externalBooks = [TestFixtures.externalBook]
        initialState.nextIndex = 1
        initialState.hasMore = true
        initialState.pageSize = 20

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        store.dependencies.externalBookService.search = { _, _, _ in
            .success([book2])
        }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.externalBooks = [TestFixtures.externalBook, book2]
            $0.nextIndex = 2
            $0.hasMore = false
        }
    }

    @Test func loadMore_guardConditions_noEffect() async {
        // Already loading
        var state1 = SearchResultFeature.State()
        state1.isLoading = true
        state1.keyword = "test"
        let store1 = TestStore(initialState: state1, reducer: { SearchResultFeature() })
        await store1.send(.loadMore)

        // Empty keyword
        var state2 = SearchResultFeature.State()
        state2.keyword = ""
        let store2 = TestStore(initialState: state2, reducer: { SearchResultFeature() })
        await store2.send(.loadMore)

        // No more pages
        var state3 = SearchResultFeature.State()
        state3.keyword = "test"
        state3.hasMore = false
        let store3 = TestStore(initialState: state3, reducer: { SearchResultFeature() })
        await store3.send(.loadMore)
    }

    @Test func cancelSearch_resetsState() async {
        var initialState = SearchResultFeature.State()
        initialState.externalBooks = [TestFixtures.externalBook]
        initialState.keyword = "swift"

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        await store.send(.cancelSearch) {
            $0.isLoading = false
            $0.isLoadingMore = false
            $0.errorMessage = nil
            $0.externalBooks = []
            $0.nextIndex = 0
            $0.hasMore = true
        }
    }

    @Test func externalBookTapped_delegatesAndSavesHistory() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        var initialState = SearchResultFeature.State()
        initialState.externalBooks = [TestFixtures.externalBook]

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.searchHistory.add = { _, _, _ in }

        await store.send(.externalBookTapped(id: "ext-001"))
        await store.receive(\.delegate)
    }

    @Test func refresh_restartsSearch() async {
        let clock = TestClock()

        var initialState = SearchResultFeature.State()
        initialState.keyword = "swift"
        initialState.externalBooks = [TestFixtures.externalBook]

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        store.dependencies.continuousClock = clock
        store.dependencies.externalBookService.search = { _, _, _ in
            .success([TestFixtures.externalBook])
        }
        store.dependencies.searchKeywordService.record = { _ in
            .success(TestFixtures.searchKeyword)
        }

        await store.send(.refresh) {
            $0.isLoading = true
            $0.errorMessage = nil
            $0.nextIndex = 0
            $0.hasMore = true
        }

        await clock.advance(by: .milliseconds(200))

        await store.receive(\.searchResponse) {
            $0.isLoading = false
            $0.externalBooks = [TestFixtures.externalBook]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func refresh_emptyKeyword_doesNothing() async {
        var initialState = SearchResultFeature.State()
        initialState.keyword = ""

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        await store.send(.refresh)
    }

    @Test func loadMoreResponse_failure_showsAlert() async {
        var initialState = SearchResultFeature.State()
        initialState.keyword = "swift"
        initialState.externalBooks = [TestFixtures.externalBook]
        initialState.isLoadingMore = true

        let store = TestStore(
            initialState: initialState,
            reducer: { SearchResultFeature() }
        )

        await store.send(.loadMoreResponse(.failure(.invalidURL))) {
            $0.isLoadingMore = false
            $0.errorMessage = ExternalBookService.ServiceError.invalidURL.localizedDescription
            $0.alert = AlertState {
                TextState("load_more_failed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("confirm")
                }
            } message: {
                TextState(ExternalBookService.ServiceError.invalidURL.localizedDescription)
            }
        }
    }
}
