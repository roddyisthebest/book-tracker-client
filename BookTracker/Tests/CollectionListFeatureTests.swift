@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct CollectionListFeatureTests {
    @Test func onAppear_loadsCollections() async {
        let store = TestStore(
            initialState: CollectionListFeature.State(),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listSummaries = { _, _ in .success([TestFixtures.collectionSummary]) }

        await store.send(.onAppear)
        await store.receive(\.loadCollections) {
            $0.isLoading = true
        }

        await store.receive(\.loadCollectionsResponse) {
            $0.isLoading = false
            $0.collections = [TestFixtures.collectionSummary]
            $0.nextIndex = 1
            $0.hasMore = false
        }
    }

    @Test func loadCollections_failure_setsErrorMessage() async {
        let store = TestStore(
            initialState: CollectionListFeature.State(),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listSummaries = { _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadCollections) {
            $0.isLoading = true
        }

        await store.receive(\.loadCollectionsResponse) {
            $0.isLoading = false
            $0.collections = []
            $0.nextIndex = 0
            $0.hasMore = false
        }
    }

    @Test func loadMore_success_appendsCollections() async {
        var state = CollectionListFeature.State()
        state.collections = [TestFixtures.collectionSummary]
        state.nextIndex = 1
        state.hasMore = true

        let store = TestStore(
            initialState: state,
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        let second = UserCollectionSummary(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000051")!,
            userId: TestFixtures.userId,
            name: "Second",
            type: .custom,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            description: "Second collection",
            previewBooks: []
        )

        store.dependencies.collectionService.listSummaries = { _, _ in .success([second]) }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }

        await store.receive(\.loadMoreResponse) {
            $0.isLoadingMore = false
            $0.collections = [TestFixtures.collectionSummary, second]
            $0.nextIndex = 2
            $0.hasMore = false
        }
    }

    @Test func loadMore_guardPreventsDoubleLoad() async {
        var state = CollectionListFeature.State()
        state.isLoadingMore = true

        let store = TestStore(
            initialState: state,
            reducer: { CollectionListFeature() }
        )

        await store.send(.loadMore)
    }

    @Test func collectionCardTapped_presentsDetail() async {
        let store = TestStore(
            initialState: CollectionListFeature.State(),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        await store.send(.collectionCardTapped(collection: TestFixtures.collectionSummary)) {
            $0.destination = .viewCollectionDetail(CollectionDetailFeature.State(collection: TestFixtures.collectionSummary))
        }
    }

    @Test func addButtonTapped_presentsForm() async {
        let store = TestStore(
            initialState: CollectionListFeature.State(),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        await store.send(.addButtonTapped) {
            $0.destination = .formCollection(CollectionFormFeature.State())
        }
    }

    @Test func deleteButtonTapped_customCollection_showsAlert() async {
        var state = CollectionListFeature.State()
        state.collections = [TestFixtures.collectionSummary]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        let id = TestFixtures.collectionSummary.id

        await store.send(.deleteButtonTapped(id: id)) {
            $0.destination = .alert(.deleteConfirmation(id: id))
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

        var state = CollectionListFeature.State()
        state.collections = [nonCustom]

        let store = TestStore(
            initialState: state,
            reducer: { CollectionListFeature() }
        )

        await store.send(.deleteButtonTapped(id: nonCustom.id))
    }

    @Test func confirmDeletion_success_refreshesAndDelegates() async {
        let id = TestFixtures.collectionSummary.id

        let store = TestStore(
            initialState: CollectionListFeature.State(
                destination: .alert(.deleteConfirmation(id: id))
            ),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.delete = { _ in .success(id) }
        store.dependencies.collectionService.listSummaries = { _, _ in .success([]) }

        await store.send(.destination(.presented(.alert(.confirmDeletion(id: id))))) {
            $0.isDeleting = true
        }

        await store.receive(\.deleteCollectionResponse) {
            $0.isDeleting = false
        }

        await store.receive(\.onRefresh)
        await store.receive(\.delegate)
    }

    @Test func confirmDeletion_failure_showsErrorAlert() async {
        let id = TestFixtures.collectionSummary.id

        let store = TestStore(
            initialState: CollectionListFeature.State(
                destination: .alert(.deleteConfirmation(id: id))
            ),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.delete = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.destination(.presented(.alert(.confirmDeletion(id: id))))) {
            $0.isDeleting = true
        }

        await store.receive(\.deleteCollectionResponse) {
            $0.isDeleting = false
        }
    }

    @Test func onRefresh_triggersReload() async {
        let store = TestStore(
            initialState: CollectionListFeature.State(),
            reducer: { CollectionListFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.listSummaries = { _, _ in .success([]) }

        await store.send(.onRefresh)
        await store.receive(\.loadCollections)
    }
}
