@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct CustomBookListFeatureTests {
    @Test func onAppear_loadsBooks() async {
        let store = TestStore(
            initialState: CustomBookListFeature.State(),
            reducer: { CustomBookListFeature() }
        )

        store.dependencies.localCustomBookService.fetchAll = { _ in .success([TestFixtures.externalBook]) }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.loadResponse) {
            $0.isLoading = false
            $0.books = [TestFixtures.externalBook]
            $0.errorMessage = nil
        }
    }

    @Test func onAppear_failure_setsError() async {
        let store = TestStore(
            initialState: CustomBookListFeature.State(),
            reducer: { CustomBookListFeature() }
        )

        store.dependencies.localCustomBookService.fetchAll = { _ in .failure(.unknown) }

        await store.send(.onAppear) {
            $0.isLoading = true
        }

        await store.receive(\.loadResponse) {
            $0.isLoading = false
            $0.errorMessage = LocalCustomBookError.unknown.localizedDescription
        }
    }

    @Test func deleteTapped_removesBookAndCallsService() async {
        let store = TestStore(
            initialState: CustomBookListFeature.State(
                books: [TestFixtures.externalBook]
            ),
            reducer: { CustomBookListFeature() }
        )

        store.dependencies.localCustomBookService.remove = { id, _ in .success(id) }

        await store.send(.deleteTapped(id: "ext-001")) {
            $0.books = []
        }

        await store.receive(\.deleteResponse)
    }

    @Test func clearAllTapped_success_clearsBooks() async {
        let store = TestStore(
            initialState: CustomBookListFeature.State(
                books: [TestFixtures.externalBook]
            ),
            reducer: { CustomBookListFeature() }
        )

        store.dependencies.localCustomBookService.clearAll = { _ in .success(()) }

        await store.send(.clearAllTapped)

        await store.receive(\.clearAllResponse) {
            $0.books = []
        }
    }

    @Test func clearAllTapped_failure_keepsBooks() async {
        let store = TestStore(
            initialState: CustomBookListFeature.State(
                books: [TestFixtures.externalBook]
            ),
            reducer: { CustomBookListFeature() }
        )

        store.dependencies.localCustomBookService.clearAll = { _ in .failure(.unknown) }

        await store.send(.clearAllTapped)

        await store.receive(\.clearAllResponse)
    }

    @Test func bookTapped_delegatesOpenBook() async {
        let store = TestStore(
            initialState: CustomBookListFeature.State(),
            reducer: { CustomBookListFeature() }
        )

        await store.send(.bookTapped(TestFixtures.externalBook))
        await store.receive(\.delegate)
    }
}
