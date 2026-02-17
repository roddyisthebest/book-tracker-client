//
//  SearchResultFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchResultFeature {
    @ObservableState
    struct State: Equatable {
        var externalBooks: [ExternalBook] = [
            ExternalBook(id: "1", title: "이렇게산다고"),
            ExternalBook(id: "2", title: "못쓰게된 너라고"),
        ]
        var keyword: String = ""
    }

    enum Action: Equatable {
        case externalBookTapped(id: String)

        case delegate(Delegate)

        enum Delegate: Equatable {
            case tapBook(id: String)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            _, action in
            switch action {
            case .externalBookTapped(let id):
                return .send(.delegate(.tapBook(id: id)))
            case .delegate:
                return .none
            }
        }
    }
}
