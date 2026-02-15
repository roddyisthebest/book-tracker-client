//
//  BookDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct BookDetailFeature {
    @ObservableState
    struct State: Equatable {
        var book: Book?
        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case deleteButtonTapped
        case updateButtonTapped
        case moreButtonTapped

        case statusUpdateButtonTapped(StatusEditButtonKind)
        enum StatusEditButtonKind: Equatable {
            case done
            case dropped
            case returned
            case reading
        }

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmDeletion
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .deleteButtonTapped:
                state.destination = .alert(.deleteConfirmation())
                return .none
            case .updateButtonTapped:
                state.destination = .formBook(BookFormFeature.State(externalId: "ss", bookId: UUID(1)))
                return .none
            case .moreButtonTapped:
                return .none
            case .statusUpdateButtonTapped(.done):
                return .none
            case .statusUpdateButtonTapped:
                return .none
            case .destination(.presented(.alert(.confirmDeletion))):
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension BookDetailFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case formBook(BookFormFeature)
        case alert(AlertState<BookDetailFeature.Action.Alert>)
    }
}

extension AlertState where Action == BookDetailFeature.Action.Alert {
    static func deleteConfirmation() -> Self {
        Self {
            TextState("Are you sure?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("Delete")
            }
        }
    }
}
