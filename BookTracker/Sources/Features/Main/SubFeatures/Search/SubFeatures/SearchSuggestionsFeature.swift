//
//  SearchSuggestionsFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SearchSuggestionsFeature {
    @ObservableState
    struct State: Equatable {
        var searches: [Search] = [
            Search(id: UUID(1), text: "괜찮아 괜찮43괜찮아 괜찮asdddsasd asdasdfdfadasdfsadfdsafdsfdsf", createdAt: Date()),
            Search(id: UUID(2), text: "마이노2", createdAt: Date()),
            Search(id: UUID(3), text: "괜찮아 괜찮43괜찮아 괜찮43 괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43", createdAt: Date()),
        ]
        var books: [ExternalBook] = [
            ExternalBook(id: "ad2231", title: "괜찮아 괜찮43괜찮아 괜찮asdddsasd asdasdfdfadasdfsadfdsafdsfdsf"),
            ExternalBook(id: "ad2232", title: "마이노2"),
            ExternalBook(id: "ad2233", title: "괜찮아 괜찮43괜찮아 괜찮43 괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43"),
        ]
    }

    enum Action: Equatable {
        case searchTapped(text: String)
        case deleteButtonTapped(id: UUID)

        case delegate(Delegate)
        enum Delegate: Equatable {
            case setKeyword(String)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
                case .searchTapped(let text):
                    return .send(.delegate(.setKeyword(text)))
                case .deleteButtonTapped(let id):
                    state.searches.removeAll(where: { $0.id == id })
                    return .none
                case .delegate:
                    return .none
            }
        }
    }
}
