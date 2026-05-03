@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct LibraryFeatureTests {
    @Test func onAppear_loadsAllSections() async {
        let store = TestStore(
            initialState: LibraryFeature.State(),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.bookService.statusCounts = { .success([.reading: 1, .want: 2, .done: 3, .dropped: 0]) }
        store.dependencies.collectionService.listSummaries = { _, _ in .success([TestFixtures.collectionSummary]) }
        store.dependencies.receiptService.loadReceipts = { _, _, _ in .success([TestFixtures.receiptSummary]) }

        await store.send(.onAppear)

        await store.receive(\.loadStatusCounts)
        await store.receive(\.loadCollections)
        await store.receive(\.loadRecentReceipts)

        // 비동기 응답은 완료 순서가 비결정적이므로 개별 테스트에서 검증
    }

    @Test func statusCountsResponse_success_setsCounts() async {
        var state = LibraryFeature.State()
        state.isLoadingStatusCounts = true

        let store = TestStore(
            initialState: state,
            reducer: { LibraryFeature() }
        )

        let counts: [BookStatus: Int] = [.reading: 1, .want: 2, .done: 3, .dropped: 0]
        await store.send(.statusCountsResponse(.success(counts))) {
            $0.isLoadingStatusCounts = false
            $0.statusCounts = .success(counts)
        }
    }

    @Test func statusCountsResponse_failure_setsFailure() async {
        var state = LibraryFeature.State()
        state.isLoadingStatusCounts = true

        let store = TestStore(
            initialState: state,
            reducer: { LibraryFeature() }
        )

        await store.send(.statusCountsResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoadingStatusCounts = false
            $0.statusCounts = .failure(.unknown(message: "fail"))
        }
    }

    @Test func collectionsResponse_success_setsCollections() async {
        var state = LibraryFeature.State()
        state.isLoadingCollections = true

        let store = TestStore(
            initialState: state,
            reducer: { LibraryFeature() }
        )

        await store.send(.collectionsResponse(.success([TestFixtures.collectionSummary]))) {
            $0.isLoadingCollections = false
            $0.collections = .success([TestFixtures.collectionSummary])
        }
    }

    @Test func collectionsResponse_failure_setsFailure() async {
        var state = LibraryFeature.State()
        state.isLoadingCollections = true

        let store = TestStore(
            initialState: state,
            reducer: { LibraryFeature() }
        )

        await store.send(.collectionsResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoadingCollections = false
            $0.collections = .failure(.unknown(message: "fail"))
        }
    }

    @Test func recentReceiptsResponse_success_setsReceipts() async {
        var state = LibraryFeature.State()
        state.isLoadingRecentReceipts = true

        let store = TestStore(
            initialState: state,
            reducer: { LibraryFeature() }
        )

        await store.send(.recentReceiptsResponse(.success([TestFixtures.receiptSummary]))) {
            $0.isLoadingRecentReceipts = false
            $0.recentReceipts = .success([TestFixtures.receiptSummary])
        }
    }

    @Test func recentReceiptsResponse_failure_setsFailure() async {
        var state = LibraryFeature.State()
        state.isLoadingRecentReceipts = true

        let store = TestStore(
            initialState: state,
            reducer: { LibraryFeature() }
        )

        await store.send(.recentReceiptsResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoadingRecentReceipts = false
            $0.recentReceipts = .failure(.unknown(message: "fail"))
        }
    }

    @Test func sectionTapped_myBooks_appendsPath() async {
        let store = TestStore(
            initialState: LibraryFeature.State(),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        await store.send(.sectionTapped(.myBooks(status: .reading))) {
            $0.path[id: 0] = .myBooks(MyBookListFeature.State(bookStatus: .reading))
        }
    }

    @Test func sectionTapped_collections_appendsPath() async {
        let store = TestStore(
            initialState: LibraryFeature.State(),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        await store.send(.sectionTapped(.collections)) {
            $0.path[id: 0] = .collections(CollectionListFeature.State())
        }
    }

    @Test func sectionTapped_receipts_appendsPath() async {
        let store = TestStore(
            initialState: LibraryFeature.State(),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        await store.send(.sectionTapped(.receipts)) {
            $0.path[id: 0] = .receipts(ReceiptListFeature.State())
        }
    }

    @Test func collectionCardTapped_presentsDetail() async {
        let store = TestStore(
            initialState: LibraryFeature.State(),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        await store.send(.collectionCardTapped(collection: TestFixtures.collectionSummary)) {
            $0.destination = .collectionDetail(CollectionDetailFeature.State(collection: TestFixtures.collectionSummary))
        }
    }

    @Test func receiptCardTapped_presentsDetail() async {
        let id = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: LibraryFeature.State(),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        await store.send(.receiptCardTapped(id: id)) {
            $0.destination = .receiptDetail(ReceiptDetailFeature.State(id: id))
        }
    }

    @Test func deleteCollectionConfirm_success_reloadsCollections() async {
        let collectionId = TestFixtures.collectionSummary.id

        let store = TestStore(
            initialState: LibraryFeature.State(
                collections: .success([TestFixtures.collectionSummary]),
                destination: .alert(.deleteCollectionConfirmation(id: collectionId))
            ),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.collectionService.delete = { _ in .success(UUID()) }
        store.dependencies.collectionService.listSummaries = { _, _ in .success([]) }

        await store.send(.destination(.presented(.alert(.confirmCollectionDeletion(id: collectionId))))) {
            $0.destination = nil
            $0.isDeletingCollection = true
        }

        await store.receive(\.deleteCollectionResponse) {
            $0.isDeletingCollection = false
        }

        await store.receive(\.loadCollections)
        await store.receive(\.collectionsResponse)
    }

    @Test func deleteReceiptConfirm_failure_showsAlert() async {
        let receiptId = TestFixtures.receiptSummary.id

        let store = TestStore(
            initialState: LibraryFeature.State(
                destination: .alert(.deleteReceiptConfirmation(id: receiptId))
            ),
            reducer: { LibraryFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.deleteReceipt = { _ in
            .failure(.unknown(message: "fail"))
        }

        await store.send(.destination(.presented(.alert(.confirmReceiptDeletion(id: receiptId))))) {
            $0.destination = nil
            $0.isDeletingReceipt = true
        }

        await store.receive(\.deleteReceiptResponse) {
            $0.isDeletingReceipt = false
            $0.destination = .alert(.showReceiptDeletionErrorAlert())
        }
    }
}
