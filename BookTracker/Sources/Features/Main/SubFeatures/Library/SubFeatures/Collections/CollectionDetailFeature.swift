//
//  CollectionDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/9/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CollectionDetailFeature {
    @Dependency(\.collectionService) var collectionService

    @ObservableState
    struct State: Equatable {
        var collection: UserCollectionSummary

        var books: [Book] = []
        var sortOption: BookSortOption = .newest

        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var isError: Bool = false

        var nextIndex: Int = 0
        var pageSize: Int = 20
        var hasMore: Bool = true

        var isDeleting: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case onAppear

        case loadBooks
        case loadBooksResponse(Result<[Book], AppError>)

        case loadMore
        case loadMoreResponse(Result<[Book], AppError>)

        case onRefresh

        case editButtonTapped(EditButtonKind)

        case bookCardTapped(UUID)
        case deleteButtonTapped

        case deletionResponse(Result<UUID, AppError>)

        case destination(PresentationAction<Destination.Action>)

        case delegate(Delegate)

        enum Delegate: Equatable {
            case deleteCollection(id: UUID)
        }

        enum Alert: Equatable {
            case confirmDeletion
        }

        enum EditButtonKind: Equatable {
            case books
            case collection
        }
    }

    private enum CancelID {
        case loadBooks
        case loadMore
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce {
            state, action in
            switch action {
            case .onAppear:
                return .send(.loadBooks)
            case .onRefresh:
                return .send(.onAppear)
            case .loadBooks:
                state.isLoading = true
                state.isError = false
                state.nextIndex = 0
                state.hasMore = true

                let collectionId = state.collection.id
                let pageSize = state.pageSize

                return .merge(
                    .cancel(id: CancelID.loadMore),
                    .run { send in
                        let result = await collectionService.listBooks(collectionId, pageSize, 0)
                        await send(.loadBooksResponse(result))
                    }
                    .cancellable(id: CancelID.loadBooks, cancelInFlight: true)
                )
            case .loadBooksResponse(.success(let books)):
                state.isLoading = false
                state.books = books
                state.nextIndex = books.count
                state.hasMore = books.count == state.pageSize
                return .none
            case .loadBooksResponse(.failure(let error)):
                state.isLoading = false
                state.books = []
                state.isError = true
                state.nextIndex = 0
                state.hasMore = false
                return .none
            case .loadMore:
                guard !state.isLoading,
                      !state.isLoadingMore,
                      state.hasMore
                else {
                    return .none
                }

                state.isLoadingMore = true

                let collectionId = state.collection.id
                let pageSize = state.pageSize
                let nextIndex = state.nextIndex

                return .run { send in
                    let result = await collectionService.listBooks(collectionId, pageSize, nextIndex)
                    await send(.loadMoreResponse(result))
                }
                .cancellable(id: CancelID.loadMore, cancelInFlight: true)
            case .loadMoreResponse(.success(let books)):
                state.isLoadingMore = false
                state.books.append(contentsOf: books)
                state.nextIndex += books.count
                state.hasMore = books.count == state.pageSize
                return .none
            case .loadMoreResponse(.failure(let error)):
                state.isLoadingMore = false
                state.destination = .alert(.showInfiniteFetchingErrorMessage())
                return .none
            case .editButtonTapped(.books):
                state.destination = .selectBooks(CollectionSelectBooksFeature.State(collection: state.collection.toUserCollection()))
                return .none
            case .editButtonTapped(.collection):
                guard state.collection.type == .custom else { return .none }
                state.destination = .formCollection(CollectionFormFeature.State(collection: state.collection.toUserCollection()))
                return .none
            case .bookCardTapped:
                return .none
            case .deleteButtonTapped:
                guard state.collection.type == .custom else { return .none }
                state.destination = .alert(.deleteConfirmation())
                return .none
            case .destination(.presented(.formCollection(.delegate(.updateCollection(let collection))))):
                state.destination = nil
                state.collection.name = collection.name ?? ""
                state.collection.description = collection.description ?? ""
                return .none
            case .destination(.presented(.selectBooks(.delegate(.updateCollection)))):
                state.destination = nil
                return .send(.loadBooks)
            case .destination(.presented(.alert(.confirmDeletion))):
                state.isDeleting = true
                return .run {
                    [id = state.collection.id] send in
                    let result = try await collectionService.delete(id)
                    await send(.deletionResponse(result))
                }
            case .deletionResponse(let result):
                state.isDeleting = false
                switch result {
                case .success(let id):
                    return .send(.delegate(.deleteCollection(id: id)))
                case .failure:
                    state.destination = .alert(.showDeletionFailedAlert())
                    return .none
                }
            case .destination:
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }.ifLet(\.$destination, action: \.destination)
    }
}

extension CollectionDetailFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case selectBooks(CollectionSelectBooksFeature)
        case formCollection(CollectionFormFeature)
        case alert(AlertState<CollectionDetailFeature.Action.Alert>)
    }
}

extension AlertState where Action == CollectionDetailFeature.Action.Alert {
    static func deleteConfirmation() -> Self {
        Self {
            TextState("are_you_sure")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("delete")
            }
        }
    }

    static func showDeletionFailedAlert() -> Self {
        Self {
            TextState("collection_delete_failed")
        }
    }

    static func showInfiniteFetchingErrorMessage() -> Self {
        Self {
            TextState("load_more_failed_retry")
        }
    }
}
