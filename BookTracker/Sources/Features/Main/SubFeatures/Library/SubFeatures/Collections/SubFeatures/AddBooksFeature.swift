//
//  CollectionAddBooksFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/9/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddBooksFeature {
    @ObservableState
    struct State: Equatable {
        var books: [Book] = []
        var selectedIds: Set<UUID> = []
        var keyword: String = ""

        let unSelectableIds: Set<UUID>?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case bookSelected(UUID)
        case delegate(Delegate)
        case addButtonTapped
        enum Delegate: Equatable {
            case addBooksToCollection([Book])
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .bookSelected(let id):
                let isSelected = state.selectedIds.contains(id)
                if isSelected {
                    state.selectedIds.remove(id)
                }
                else {
                    state.selectedIds.insert(id)
                }
                return .none
            case .addButtonTapped:
                return .send(.delegate(.addBooksToCollection(state.selectedBooks)))
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

extension AddBooksFeature.State {
    var filteredBooks: [Book] {
        books.filter {
            let bookId = $0.id
            if let unSelectableIds, unSelectableIds.contains(bookId) {
                return false
            }

            if keyword.isEmpty {
                return true
            }

            return $0.title.contains(keyword) || $0.author.contains(keyword)
        }
    }

    var selectedBooks: [Book] {
        books.filter { selectedIds.contains($0.id) }
    }

    var isSubmitEnabled: Bool {
        selectedIds.count > 0
    }
}
