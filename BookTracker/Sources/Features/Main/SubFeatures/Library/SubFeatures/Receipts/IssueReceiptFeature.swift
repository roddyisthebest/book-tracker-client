//
//  Untitled.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct IssueReceiptFeature {
    @ObservableState
    struct State: Equatable {
        var externalBookIds: Set<String> = []

        var type: ReceiptType = .rental

        // .rental
        var libraryName: String = ""
        var borrowedAt: Date = .init()

        // .purchase
        var storeName: String = ""
        var payedAt: Date = .init()
        var price: String = ""
    }

    enum Action: Equatable, BindableAction {
        case issueButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case issueReceiptCompleted
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> {
            _, action in
            switch action {
            case .issueButtonTapped:
                return .run {
                    send in
                    await send(.delegate(.issueReceiptCompleted))
                }
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
