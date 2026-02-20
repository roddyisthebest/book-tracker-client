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
            Book.make(
                id: UUID(1),
                title: "모비 딕",
                author: "허먼 멜빌",
                publisher: "문학사상",
                isbn: "9781234567001",
                status: .want,
                type: .paper
            ),
            Book.make(
                id: UUID(2),
                title: "데미안",
                author: "헤르만 헤세",
                publisher: "민음사",
                isbn: "9781234567002",
                status: .reading,
                type: .ebook
            ),
            Book.make(
                id: UUID(3),
                title: "자기 개발서",
                author: "홍길동",
                publisher: "한빛미디어",
                isbn: "9781234567003",
                status: .done,
                type: .paper
            ),
            Book.make(
                id: UUID(4),
                title: "스위프트 마스터",
                author: "애플",
                publisher: "애플프레스",
                isbn: "9781234567004",
                status: .dropped,
                type: .ebook
            )
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
