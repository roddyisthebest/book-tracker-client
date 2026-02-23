//
//  MyInfoFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture

enum LoginMethod: Equatable {
    case apple
    case google
    case local
}

@Reducer
struct MyInfoFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = "배성연"
        var email: String?
        var imageUrl: String?
        var loginMethod: LoginMethod?

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case nameEditButtonTapped
        case profileImageViewTapped

        case destination(PresentationAction<Destination.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .nameEditButtonTapped:
                state.destination = .updateName(UpdateNameFeature.State(name: state.name))
                return .none
            case .profileImageViewTapped:
                return .none
            case .destination(.presented(.updateName(.delegate(.setName(let updated))))):
                state.destination = nil
                state.name = updated
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension MyInfoFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case updateName(UpdateNameFeature)
    }
}
