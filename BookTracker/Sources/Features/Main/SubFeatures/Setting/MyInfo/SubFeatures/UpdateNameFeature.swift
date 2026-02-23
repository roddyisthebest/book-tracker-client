//
//  NameFieldFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct UpdateNameFeature {
    @ObservableState
    struct State: Equatable {
        var name: String
        private var initialName: String
        var isSubmittable: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines) != initialName && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        init(name: String = "") {
            self.name = name
            self.initialName = name
        }
    }

    enum Action: Equatable, BindableAction {
        case updateButtonTapped
        case binding(BindingAction<State>)

        case delegate(Delegate)
        enum Delegate: Equatable {
            case setName(name: String)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> {
            state, action in
            switch action {
            case .updateButtonTapped:
                return .send(.delegate(.setName(name: state.name.trimmingCharacters(in: .whitespacesAndNewlines))))
            case .delegate:
                return .none
            case .binding:
                return .none
            }
        }
    }
}
