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
    @ObservableState
    struct State: Equatable {
        var books: [Book] = [
        ]
        var sortOption: BookSortOption = .newest
        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case editButtonTapped(EditButtonKind)
        case bookCardTapped(UUID)
        case deleteButtonTapped(UUID)

        case destination(PresentationAction<Destination.Action>)

        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
        }

        enum EditButtonKind: Equatable {
            case books
            case collection
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce {
            state, action in
            switch action {
            case .editButtonTapped(.books):
                state.destination = .selectBooks(CollectionSelectBooksFeature.State())
                return .none
            case .editButtonTapped(.collection):
                state.destination = .formCollection(CollectionFormFeature.State())
                return .none
            case .bookCardTapped:
                return .none
            case .deleteButtonTapped(let id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case .destination(.presented(.selectBooks(.delegate(.updateCollection)))):
                // Dismiss selectBooks and update books when collection updates
                state.destination = nil
                // TODO: Update state.books based on selection
                return .none
            case .destination(.presented(.alert(.confirmDeletion))):
                return .none
            case .destination:
                return .none
            case .binding:
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
