//
//  AuthFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/2/26.
//

import ComposableArchitecture
import Foundation

enum SnsLoginMethod: Equatable {
    case apple
    case google
}

@Reducer
struct AuthFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action {
        case snsLoginButtonTapped(SnsLoginMethod)

        case delegate(Delegate)
        enum Delegate: Equatable {
            case login
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
                case .snsLoginButtonTapped(let method):
                    return .send(.delegate(.login))
                case .delegate:
                    return .none
            }
        }
    }
}
