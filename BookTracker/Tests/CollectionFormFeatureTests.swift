@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct CollectionFormFeatureTests {
    @Test func createButtonTapped_validInput_creates() async {
        var state = CollectionFormFeature.State()
        state.title = "New Collection"
        state.description = "A description"

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.createWithBooks = { _, _ in .success(TestFixtures.userCollection) }

        await store.send(.createButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.creationResponse) {
            $0.isLoading = false
        }
    }

    @Test func createButtonTapped_emptyTitle_doesNothing() async {
        var state = CollectionFormFeature.State()
        state.title = ""
        state.description = "A description"

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )

        await store.send(.createButtonTapped)
    }

    @Test func createButtonTapped_withExistingId_doesNothing() async {
        var state = CollectionFormFeature.State(collection: TestFixtures.userCollection)
        state.title = "Updated"
        state.description = "Updated desc"

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )

        await store.send(.createButtonTapped)
    }

    @Test func creationResponse_success_showsAlert() async {
        let store = TestStore(
            initialState: CollectionFormFeature.State(),
            reducer: { CollectionFormFeature() }
        )

        await store.send(.creationResponse(.success(TestFixtures.userCollection))) {
            $0.isLoading = false
            $0.alert = .showCreateConfirmation()
        }
    }

    @Test func creationResponse_failure_showsAlert() async {
        let store = TestStore(
            initialState: CollectionFormFeature.State(),
            reducer: { CollectionFormFeature() }
        )

        await store.send(.creationResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoading = false
            $0.alert = .showCreationErrorAlert()
        }
    }

    @Test func updateButtonTapped_validInput_updates() async {
        var state = CollectionFormFeature.State(collection: TestFixtures.userCollection)
        state.title = "Updated Title"
        state.description = "Updated Desc"

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.update = { _, _ in .success(TestFixtures.userCollection) }

        await store.send(.updateButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.updateResponse) {
            $0.isLoading = false
        }

        await store.receive(\.delegate)
    }

    @Test func updateButtonTapped_noId_doesNothing() async {
        var state = CollectionFormFeature.State()
        state.title = "Title"
        state.description = "Desc"

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )

        await store.send(.updateButtonTapped)
    }

    @Test func updateResponse_success_delegatesUpdate() async {
        let state = CollectionFormFeature.State(collection: TestFixtures.userCollection)

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )
        store.exhaustivity = .off

        await store.send(.updateResponse(.success(TestFixtures.userCollection))) {
            $0.isLoading = false
        }

        await store.receive(\.delegate)
    }

    @Test func updateResponse_failure_showsAlert() async {
        let store = TestStore(
            initialState: CollectionFormFeature.State(collection: TestFixtures.userCollection),
            reducer: { CollectionFormFeature() }
        )

        await store.send(.updateResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoading = false
            $0.alert = .showUpdateErrorAlert()
        }
    }

    @Test func confirmCreation_delegatesRefresh() async {
        var state = CollectionFormFeature.State()
        state.alert = .showCreateConfirmation()

        let store = TestStore(
            initialState: state,
            reducer: { CollectionFormFeature() }
        )
        store.exhaustivity = .off

        await store.send(.alert(.presented(.confirmCreation))) {
            $0.alert = nil
        }

        await store.receive(\.delegate)
    }

    @Test func presentBookPicker_opensAddBooks() async {
        let store = TestStore(
            initialState: CollectionFormFeature.State(),
            reducer: { CollectionFormFeature() }
        )
        store.exhaustivity = .off

        await store.send(.presentBookPickerButtonTapped) {
            $0.addBooks = AddBooksFeature.State(selectedIds: [])
        }
    }
}
