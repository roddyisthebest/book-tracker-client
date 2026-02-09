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
            Book(id: UUID(1), title: "테스트", author: "테스트", publisher: "테스트", imageUrl: nil, isbn: "9788936429430"),
            Book(id: UUID(2), title: "테스트2", author: "테스트2", publisher: "테스트2", imageUrl: nil, isbn: "9788936429431"),
            Book(id: UUID(3), title: "테스트3", author: "테스트3", publisher: "테스트3", imageUrl: nil, isbn: "9788936429432"),
        ]

        @Presents var alert: AlertState<CollectionSelectBooksFeature.Action.Alert>?
    }

    enum Action {
        case bookSelected(id: UUID)
        case bookAllSelected
        case bookAllDisselected
        case addButtonTapped
        case deleteButtonTapped
        case delegate(Delegate)
        case alert(PresentationAction<Alert>)

        enum Delegate {
            case addBooksToCollection(books: [Book])
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
                let selectedBooks = state.books.filter { state.selectedIds.contains($0.id) }

                if selectedBooks.isEmpty {
                    return .none
                }

                return .send(.delegate(.addBooksToCollection(books: selectedBooks)))
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
            case .delegate:
                return .none
            }
        }.ifLet(\.$alert, action: \.alert)
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
