//
//  CollectionListFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/10/26.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct CollectionListFeature {
    @Dependency(\.collectionService) var collectionService

    @ObservableState
    struct State: Equatable {
        var collections: [UserCollectionSummary] = []

        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var errorMessage: String? = nil

        var nextIndex: Int = 0
        var pageSize: Int = 40
        var hasMore: Bool = true

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case onAppear

        case loadCollections
        case loadCollectionsResponse(Result<[UserCollectionSummary], AppError>)

        case loadMore
        case loadMoreResponse(Result<[UserCollectionSummary], AppError>)

        case onRefresh

        case deleteButtonTapped(id: UUID)
        case updateButtonTapped(id: UUID)
        case addButtonTapped
        case collectionCardTapped(collection: UserCollectionSummary)
        case destination(PresentationAction<Destination.Action>)
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
        }
    }

    private enum CancelID {
        case loadCollections
        case loadMore
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case .onAppear:
                return .send(.loadCollections)
            case .loadCollections:
                state.isLoading = true
                state.errorMessage = nil
                state.nextIndex = 0
                state.hasMore = true
                let pageSize = state.pageSize
                return .merge(
                    .cancel(id: CancelID.loadCollections),
                    .run {
                        send in
                        let result = try await collectionService.listSummaries(pageSize, 0)
                        await send(.loadCollectionsResponse(result))
                    }
                    .cancellable(id: CancelID.loadCollections, cancelInFlight: true)
                )
            case .loadCollectionsResponse(.success(let collections)):
                state.isLoading = false
                state.collections = collections
                state.nextIndex = collections.count
                state.hasMore = collections.count == state.pageSize
                return .none
            case .loadCollectionsResponse(.failure(let error)):
                state.isLoading = false
                state.collections = []
                state.errorMessage = error.localizedDescription
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
                let pageSize = state.pageSize
                let nextIndex = state.nextIndex
                return .run { send in
                    let result = try await collectionService.listSummaries(pageSize, nextIndex)
                    await send(.loadMoreResponse(result))
                }
                .cancellable(id: CancelID.loadMore, cancelInFlight: true)
            case .loadMoreResponse(.success(let collections)):
                state.isLoadingMore = false
                state.collections.append(contentsOf: collections)
                state.nextIndex += collections.count
                state.hasMore = collections.count == state.pageSize
                return .none
            case .loadMoreResponse(.failure(let error)):
                state.isLoadingMore = false
                state.destination = .alert(.loadMoreFailed(message: error.localizedDescription))
                return .none
            case .onRefresh:
                return .send(.loadCollections)
            case .destination(.presented(.formCollection(.delegate(.refreshCollection)))):
                state.destination = nil
                return .send(.onRefresh)
            case .destination(.dismiss):
                return .none
            case .destination(.presented(.formCollection(.delegate(.deleteCollection(id: let id))))):
                state.destination = nil
                state.collections = state.collections.filter { $0.id != id }
                return .none
            case .destination(.presented(.viewCollectionDetail(.destination(.presented(.selectBooks(.delegate(.updateCollection))))))):
                return .send(.onRefresh)
            case .destination(.presented(.viewCollectionDetail(.delegate(.deleteCollection(let id))))):
                state.destination = nil
                state.collections = state.collections.filter { $0.id != id }
                return .none
            case .destination(.presented(.viewCollectionDetail(.destination(.presented(.formCollection(.delegate(.updateCollection(let updated)))))))):
                state.collections = state.collections.map { summary in
                    summary.id == updated.id ? summary.updating(from: updated) : summary
                }
                return .none
            case .destination:
                return .none
            case .alert(.presented(.confirmDeletion(let id))):
                state.collections = state.collections.filter { $0.id != id }
                return .none
            case .alert:
                return .none
            case .collectionCardTapped(let collection):
                state.destination = .viewCollectionDetail(CollectionDetailFeature.State(collection: collection))
                return .none
            case .deleteButtonTapped(let id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case .updateButtonTapped(let id):
                guard let collection = state.collections.first(where: { $0.id == id }) else {
                    return .none
                }
//                state.destination = .formCollection(CollectionFormFeature.State(collection: collection))
                return .none
            case .addButtonTapped:
                state.destination = .formCollection(CollectionFormFeature.State())
                return .none
            }
        }.ifLet(\.$destination, action: \.destination)
    }
}

extension CollectionListFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case formCollection(CollectionFormFeature)
        case viewCollectionDetail(CollectionDetailFeature)
        case alert(AlertState<CollectionListFeature.Action.Alert>)
    }
}

extension AlertState where Action == CollectionListFeature.Action.Alert {
    static func deleteConfirmation(id: UUID) -> Self {
        Self {
            TextState("Are you sure?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                TextState("Delete")
            }
        }
    }

    static func loadMoreFailed(message: String) -> Self {
        Self {
            TextState("더 불러오기에 실패했어요")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        } message: {
            TextState(message)
        }
    }
}
