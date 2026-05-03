@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct SearchSuggestionsFeatureTests {
    @Test func onAppear_loadsKeywordsAndRecents() async {
        let keywords = [TestFixtures.searchKeyword]
        let recents = [Search(id: "1", text: "swift", createdAt: Date())]

        let store = TestStore(
            initialState: SearchSuggestionsFeature.State(),
            reducer: { SearchSuggestionsFeature() }
        )

        store.exhaustivity = .off
        store.dependencies.searchKeywordService.list = { _ in .success(keywords) }
        store.dependencies.searchHistory.fetchRecent = { _, _ in recents }

        await store.send(.onAppear)

        await store.receive(\.loadRecents) {
            $0.isSearchesLoading = true
        }
        await store.receive(\.loadSearchKeyword) {
            $0.isSearchKeywordsLoading = true
        }
    }

    @Test func loadRecentsResponse_success_setsRecents() async {
        var state = SearchSuggestionsFeature.State()
        state.isSearchesLoading = true

        let recents = [Search(id: "1", text: "swift", createdAt: Date(timeIntervalSince1970: 1_700_000_000))]

        let store = TestStore(
            initialState: state,
            reducer: { SearchSuggestionsFeature() }
        )

        await store.send(.loadRecentsResponse(.success(recents))) {
            $0.isSearchesLoading = false
            $0.searchesResult = .success(recents)
        }
    }

    @Test func loadRecentsResponse_failure_setsError() async {
        var state = SearchSuggestionsFeature.State()
        state.isSearchesLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { SearchSuggestionsFeature() }
        )

        await store.send(.loadRecentsResponse(.failure(.unknown(message: "fail")))) {
            $0.isSearchesLoading = false
            $0.searchesResult = .failure(.unknown(message: "fail"))
        }
    }

    @Test func loadSearchKeywordResponse_failure_setsError() async {
        var state = SearchSuggestionsFeature.State()
        state.isSearchKeywordsLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { SearchSuggestionsFeature() }
        )

        await store.send(.loadSearchKeywordResponse(.failure(.unknown(message: "fail")))) {
            $0.isSearchKeywordsLoading = false
            $0.searchKeywordsResult = .failure(.unknown(message: "fail"))
        }
    }

    @Test func searchTapped_delegatesAndSavesHistory() async {
        let store = TestStore(
            initialState: SearchSuggestionsFeature.State(),
            reducer: { SearchSuggestionsFeature() }
        )

        store.dependencies.date = .constant(Date(timeIntervalSince1970: 1_700_000_000))
        store.dependencies.searchHistory.add = { _, _, _ in }

        await store.send(.searchTapped(text: "swift"))
        await store.receive(\.delegate)
    }

    @Test func deleteButtonTapped_removesFromList() async {
        let search1 = Search(id: "1", text: "swift", createdAt: Date())
        let search2 = Search(id: "2", text: "kotlin", createdAt: Date())

        let store = TestStore(
            initialState: SearchSuggestionsFeature.State(
                searchesResult: .success([search1, search2])
            ),
            reducer: { SearchSuggestionsFeature() }
        )

        store.dependencies.searchHistory.delete = { _, _ in }

        await store.send(.deleteButtonTapped(id: "1")) {
            $0.searchesResult = .success([search2])
        }
    }

    @Test func cancelLoading_cancelsEffects() async {
        var state = SearchSuggestionsFeature.State()
        state.isSearchKeywordsLoading = true
        state.isSearchesLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { SearchSuggestionsFeature() }
        )

        await store.send(.cancelLoading) {
            $0.isSearchKeywordsLoading = false
            $0.isSearchesLoading = false
        }
    }

    @Test func loadSearchKeyword_loading_thenResponse() async {
        let store = TestStore(
            initialState: SearchSuggestionsFeature.State(),
            reducer: { SearchSuggestionsFeature() }
        )

        store.dependencies.searchKeywordService.list = { _ in .success([TestFixtures.searchKeyword]) }

        await store.send(.loadSearchKeyword) {
            $0.isSearchKeywordsLoading = true
        }

        await store.receive(\.loadSearchKeywordResponse) {
            $0.isSearchKeywordsLoading = false
            $0.searchKeywordsResult = .success([TestFixtures.searchKeyword])
        }
    }

    // MARK: - Custom Book Delegates

    @Test func addCustomBookTapped_delegatesAddCustomBook() async {
        let store = TestStore(
            initialState: SearchSuggestionsFeature.State(),
            reducer: { SearchSuggestionsFeature() }
        )

        await store.send(.addCustomBookTapped)
        await store.receive(\.delegate)
    }

    @Test func openCustomBookListTapped_delegatesOpenCustomBookList() async {
        let store = TestStore(
            initialState: SearchSuggestionsFeature.State(),
            reducer: { SearchSuggestionsFeature() }
        )

        await store.send(.openCustomBookListTapped)
        await store.receive(\.delegate)
    }
}
