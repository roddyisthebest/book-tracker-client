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
        var externalBooks: [ExternalBook] = []
        var keyword: String = ""
    }

    enum Action: Equatable {
        case externalBookTapped(id: String)
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            _, action in
            switch action {
            case .externalBookTapped(let id):
                return .none
            }
        }
    }
}
