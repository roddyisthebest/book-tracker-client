@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct BookInfoFeatureTests {
    @Test func onAppear_fetchesBook() async {
        let store = TestStore(
            initialState: BookInfoFeature.State(externalBookId: "ext-001"),
            reducer: { BookInfoFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.externalBookService.detail = { _ in .success(TestFixtures.externalBook) }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.fetchResponse) {
            $0.isLoading = false
            $0.externalBook = TestFixtures.externalBook
        }
    }

    @Test func fetchResponse_success_setsBook() async {
        let store = TestStore(
            initialState: BookInfoFeature.State(externalBookId: "ext-001"),
            reducer: { BookInfoFeature() }
        )

        await store.send(.fetchResponse(.success(TestFixtures.externalBook))) {
            $0.isLoading = false
            $0.externalBook = TestFixtures.externalBook
        }
    }

    @Test func fetchResponse_failure_setsError() async {
        let store = TestStore(
            initialState: BookInfoFeature.State(externalBookId: "ext-001"),
            reducer: { BookInfoFeature() }
        )

        let error = ExternalBookService.ServiceError.invalidURL

        await store.send(.fetchResponse(.failure(error))) {
            $0.isLoading = false
            $0.errorMessage = error.localizedDescription
        }
    }

    @Test func retryButtonTapped_triggersOnAppear() async {
        let store = TestStore(
            initialState: BookInfoFeature.State(externalBookId: "ext-001"),
            reducer: { BookInfoFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.externalBookService.detail = { _ in .success(TestFixtures.externalBook) }

        await store.send(.retryButtonTapped)
        await store.receive(\.onAppear)
    }
}
