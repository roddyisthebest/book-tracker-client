//
//  CollectionSelectBooksFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/8/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CollectionSelectBooksFeature {
    @ObservableState
    struct State: Equatable {
        var selectedIds: Set<UUID> = []
        var books: [Book] = [
            Book.make(),
        ]

        @Presents var alert: AlertState<CollectionSelectBooksFeature.Action.Alert>?
        @Presents var addBooks: AddBooksFeature.State?
    }

    enum Action: Equatable {
        case bookSelected(id: UUID)
        case bookAllSelected
        case bookAllDisselected
        case addButtonTapped
        case deleteButtonTapped
        case saveButtonTapped

        case alert(PresentationAction<Alert>)
        case addBooks(PresentationAction<AddBooksFeature.Action>)

        case delegate(Delegate)
        enum Delegate {
            case updateCollection
        }

        enum Alert {
            case confirmDeletion
        }
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case .bookSelected(let id):
                if state.selectedIds.contains(id) {
                    state.selectedIds.remove(id)
                    return .none
                }
                state.selectedIds.insert(id)
                return .none
            case .bookAllSelected:
                state.selectedIds = Set(state.books.map { $0.id })
                return .none
            case .bookAllDisselected:
                state.selectedIds.removeAll()
                return .none
            case .addButtonTapped:
                state.addBooks = AddBooksFeature.State(unSelectableIds: Set(state.books.map { $0.id }))
                return .none
            case .deleteButtonTapped:
                state.alert = AlertState {
                    TextState("Are you sure?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                }
                return .none
            case .alert(.presented(.confirmDeletion)):
                state.books = state.books.filter { !state.selectedIds.contains($0.id) }
                state.selectedIds = []
                return .none
            case .alert:
                return .none
            case .addBooks(.presented(.delegate(.addBooksToCollection(let books)))):
                state.books.append(contentsOf: books)
                state.addBooks = nil
                return .none
            case .saveButtonTapped:
                return .run {
                    send in
                    await send(.delegate(.updateCollection))
                }
            case .delegate:
                return .none
            case .addBooks:
                return .none
            }
        }
        .ifLet(\.$addBooks, action: \.addBooks) {
            AddBooksFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension CollectionSelectBooksFeature.State {
    var isAllSelected: Bool {
        if books.isEmpty {
            return false
        }

        return books.count == selectedIds.count
    }

    var isSubmitEnabled: Bool {
        selectedIds.count > 0
    }

    func isSelected(id: UUID) -> Bool {
        selectedIds.contains(id)
    }
}
