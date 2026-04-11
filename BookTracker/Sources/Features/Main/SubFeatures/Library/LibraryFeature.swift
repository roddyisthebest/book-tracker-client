//
//  LibraryFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/15/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LibraryFeature {
    @Dependency(\.bookService) var bookService
    @Dependency(\.collectionService) var collectionService
    @Dependency(\.receiptService) var receiptService

    @ObservableState
    struct State: Equatable {
        var collections: Result<[UserCollectionSummary], AppError> = .success([])
        var isLoadingCollections: Bool = false
        var isDeletingCollection: Bool = false
        var isDeletingReceipt: Bool = false

        var receipts: [Receipt] = [
            Receipt(id: UUID(1), type: .purchase, title: "alsdkkks"),
            Receipt(id: UUID(2), type: .rental, title: "2asds")
        ]

        var statusCounts: Result<[BookStatus: Int], AppError> = .success([
            .reading: 0,
            .want: 0,
            .done: 0,
            .dropped: 0
        ])

        var isLoadingStatusCounts: Bool = false

        var recentReceipts: Result<[ReceiptSummary], AppError> = .success([])
        var isLoadingRecentReceipts: Bool = false

        var path = StackState<Path.State>()

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case onAppear

        case sectionTapped(Section)
        case path(StackAction<Path.State, Path.Action>)

        case collectionCardTapped(collection: UserCollectionSummary)
        case receiptCardTapped(id: UUID)

        case loadStatusCounts
        case statusCountsResponse(Result<[BookStatus: Int], AppError>)

        case loadCollections
        case collectionsResponse(Result<[UserCollectionSummary], AppError>)

        case loadRecentReceipts
        case recentReceiptsResponse(Result<[ReceiptSummary], AppError>)

        case deleteCollectionButtonTapped(id: UUID)
        case deleteCollectionResponse(Result<UUID, AppError>)

        case deleteReceiptButtonTapped(id: UUID)
        case deleteReceiptResponse(Result<UUID, AppError>)

        case destination(PresentationAction<Destination.Action>)

        enum Section: Equatable {
            case myBooks(status: BookStatus)
            case collections
            case receipts
        }

        enum Alert: Equatable {
            case confirmCollectionDeletion(id: UUID)
            case confirmReceiptDeletion(id: UUID)
        }
    }

    private enum CancelID {
        case loadStatusCounts
        case loadCollections
        case loadRecentReceipts
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadStatusCounts),
                    .send(.loadCollections),
                    .send(.loadRecentReceipts)
                )
            case .collectionCardTapped(let collection):
                state.destination = .collectionDetail(CollectionDetailFeature.State(collection: collection))
                return .none
            case .receiptCardTapped(let id):
                state.destination = .receiptDetail(ReceiptDetailFeature.State(id: id))
                return .none
            case .loadCollections:
                state.isLoadingCollections = true
                return .run { send in
                    let result = await collectionService.listSummaries(20, 0)
                    await send(.collectionsResponse(result))
                }
                .cancellable(id: CancelID.loadCollections, cancelInFlight: true)
            case .collectionsResponse(let result):
                state.isLoadingCollections = false
                state.collections = result
                return .none
            case .loadStatusCounts:
                state.isLoadingStatusCounts = true
                return .run { [bookService] send in
                    let result = try await bookService.statusCounts()
                    await send(.statusCountsResponse(result))
                }
                .cancellable(id: CancelID.loadStatusCounts, cancelInFlight: true)
            case .statusCountsResponse(.success(let counts)):
                state.isLoadingStatusCounts = false
                state.statusCounts = .success(counts)
                return .none
            case .statusCountsResponse(.failure(let error)):
                state.isLoadingStatusCounts = false
                state.statusCounts = .failure(error)
                return .none
            case .loadRecentReceipts:
                state.isLoadingRecentReceipts = true
                return .run { send in
                    let result = await receiptService.loadReceipts(nil, 20, 0)
                    await send(.recentReceiptsResponse(result))
                }
                .cancellable(id: CancelID.loadRecentReceipts, cancelInFlight: true)
            case .recentReceiptsResponse(let result):
                state.isLoadingRecentReceipts = false
                state.recentReceipts = result
                return .none
            case .sectionTapped(.collections):
                state.path.append(.collections(CollectionListFeature.State()))
                return .none
            case .sectionTapped(.myBooks(let status)):
                state.path.append(.myBooks(MyBookListFeature.State(bookStatus: status)))
                return .none
            case .sectionTapped(.receipts):
                state.path.append(.receipts(ReceiptListFeature.State()))
                return .none
            case .destination(.presented(.receiptDetail(.delegate(.deleteReceipt)))):
                state.destination = nil
                return .send(.loadRecentReceipts)
            case .destination(.presented(.collectionDetail(.delegate(.deleteCollection)))):
                state.destination = nil
                return .send(.loadCollections)
            case .destination(.presented(.collectionDetail(.destination(.presented(.formCollection(.delegate(.updateCollection))))))):
                return .send(.loadCollections)
            case .destination(.presented(.collectionDetail(.destination(.presented(.selectBooks(.delegate(.updateCollection))))))):
                return .send(.loadCollections)
            case .path(.element(_, .collections(.delegate(.updateCollection)))):
                return .send(.loadCollections)
            case .deleteCollectionButtonTapped(let id):
                state.destination = .alert(.deleteCollectionConfirmation(id: id))
                return .none
            case .destination(.presented(.alert(.confirmCollectionDeletion(let id)))):
                state.isDeletingCollection = true
                return .run {
                    send in
                    let result = await collectionService.delete(id)
                    await send(.deleteCollectionResponse(result))
                }
            case .deleteCollectionResponse(.success):
                state.isDeletingCollection = false
                return .send(.loadCollections)
            case .deleteCollectionResponse(.failure):
                state.isDeletingCollection = false
                state.destination = .alert(.showCollectionDeletionErrorAlert())
                return .none
            case .deleteReceiptButtonTapped(let id):
                state.destination = .alert(.deleteReceiptConfirmation(id: id))
                return .none
            case .destination(.presented(.alert(.confirmReceiptDeletion(let id)))):
                state.isDeletingReceipt = true
                return .run { send in
                    let result = await receiptService.deleteReceipt(id)
                    await send(.deleteReceiptResponse(result))
                }
            case .deleteReceiptResponse(.success):
                state.isDeletingReceipt = false
                return .send(.loadRecentReceipts)
            case .deleteReceiptResponse(.failure):
                state.isDeletingReceipt = false
                state.destination = .alert(.showReceiptDeletionErrorAlert())
                return .none
            case .destination:
                return .none
            case .path:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path) {
            Path()
        }
    }
}

extension LibraryFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case myBooks(MyBookListFeature.State = .init())
            case receipts(ReceiptListFeature.State = .init())
            case collections(CollectionListFeature.State = .init())
        }

        enum Action: Equatable {
            case myBooks(MyBookListFeature.Action)
            case receipts(ReceiptListFeature.Action)
            case collections(CollectionListFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.myBooks, action: \.myBooks) {
                MyBookListFeature()
            }
            Scope(state: \.receipts, action: \.receipts) {
                ReceiptListFeature()
            }
            Scope(state: \.collections, action: \.collections) {
                CollectionListFeature()
            }
        }
    }
}

extension LibraryFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case collectionDetail(CollectionDetailFeature)
        case receiptDetail(ReceiptDetailFeature)
        case alert(AlertState<LibraryFeature.Action.Alert>)
    }
}

extension AlertState where Action == LibraryFeature.Action.Alert {
    static func deleteCollectionConfirmation(id: UUID) -> Self {
        Self {
            TextState("are_you_sure")
        } actions: {
            ButtonState(role: .destructive, action: .confirmCollectionDeletion(id: id)) {
                TextState("delete")
            }
        }
    }

    static func showCollectionDeletionErrorAlert() -> Self {
        Self {
            TextState("collection_delete_failed")
        }
    }

    static func deleteReceiptConfirmation(id: UUID) -> Self {
        Self {
            TextState("are_you_sure")
        } actions: {
            ButtonState(role: .destructive, action: .confirmReceiptDeletion(id: id)) {
                TextState("delete")
            }
        }
    }

    static func showReceiptDeletionErrorAlert() -> Self {
        Self {
            TextState("delete_failed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        } message: {
            TextState("try_again_later")
        }
    }
}
