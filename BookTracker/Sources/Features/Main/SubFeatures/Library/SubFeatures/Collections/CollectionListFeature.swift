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
    @ObservableState
    struct State: Equatable {
        var collections: [Collection] = [
            Collection(id: UUID(1), isDefault: true, title: "Hello, World!", description: "baby whay tou"),
            Collection(id: UUID(2), isDefault: true, title: "Hello, World 21!", description: "baby whay tou21"),
        ]
        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case deleteButtonTapped(id: UUID)
        case updateButtonTapped(id: UUID)
        case addButtonTapped
        case collectionCardTapped(id: UUID)
        case destination(PresentationAction<Destination.Action>)
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case .destination(.presented(.formCollection(.delegate(.createCollection(new: let collection))))):
                state.destination = nil
                state.collections.append(collection)
                return .none
            case .destination(.presented(.formCollection(.delegate(.updateCollection(updated: let collection))))):
                state.destination = nil
                if let idx = state.collections.firstIndex(where: { $0.id == collection.id }) {
                    state.collections[idx] = collection
                }
                return .none
            case .destination(.dismiss):
                return .none
            case .destination(.presented(.formCollection(.delegate(.deleteCollection(id: let id))))):
                state.destination = nil
                state.collections = state.collections.filter { $0.id != id }
                return .none
            case .destination:
                return .none
            case .alert(.presented(.confirmDeletion(let id))):
                state.collections = state.collections.filter { $0.id != id }
                return .none
            case .alert:
                return .none
            case .collectionCardTapped(let id):
                state.destination = .viewCollectionDetail(CollectionDetailFeature.State())
                return .none
            case .deleteButtonTapped(let id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case .updateButtonTapped(let id):
                guard let collection = state.collections.first(where: { $0.id == id }) else {
                    return .none
                }
                state.destination = .formCollection(CollectionFormFeature.State(collection: collection))
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
}
