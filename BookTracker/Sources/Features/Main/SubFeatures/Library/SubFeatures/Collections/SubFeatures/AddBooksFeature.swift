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
        var books: [Book] = [
            Book(id: UUID(1), title: "더미 책 1", author: "작가 1", publisher: "출판사 1", imageUrl: nil, isbn: "9780000000001", stereo: .done),
            Book(id: UUID(2), title: "더미 책 2", author: "작가 2", publisher: "출판사 2", imageUrl: nil, isbn: "9780000000002", stereo: .done),
            Book(id: UUID(3), title: "더미 책 3", author: "작가 3", publisher: "출판사 3", imageUrl: nil, isbn: "9780000000003", stereo: .done),
            Book(id: UUID(4), title: "더미 책 4", author: "작가 4", publisher: "출판사 4", imageUrl: nil, isbn: "9780000000004", stereo: .done),
            Book(id: UUID(5), title: "더미 책 5", author: "작가 5", publisher: "출판사 5", imageUrl: nil, isbn: "9780000000005", stereo: .done),
            Book(id: UUID(6), title: "더미 책 6", author: "작가 6", publisher: "출판사 6", imageUrl: nil, isbn: "9780000000006", stereo: .done),
            Book(id: UUID(7), title: "더미 책 7", author: "작가 7", publisher: "출판사 7", imageUrl: nil, isbn: "9780000000007", stereo: .done),
            Book(id: UUID(8), title: "더미 책 8", author: "작가 8", publisher: "출판사 8", imageUrl: nil, isbn: "9780000000008", stereo: .done),
            Book(id: UUID(9), title: "더미 책 9", author: "작가 9", publisher: "출판사 9", imageUrl: nil, isbn: "9780000000009", stereo: .done),
            Book(id: UUID(10), title: "더미 책 10", author: "작가 10", publisher: "출판사 10", imageUrl: nil, isbn: "9780000000010", stereo: .done),
            Book(id: UUID(11), title: "더미 책 11", author: "작가 11", publisher: "출판사 11", imageUrl: nil, isbn: "9780000000011", stereo: .done),
            Book(id: UUID(12), title: "더미 책 12", author: "작가 12", publisher: "출판사 12", imageUrl: nil, isbn: "9780000000012", stereo: .done)
        ]
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
