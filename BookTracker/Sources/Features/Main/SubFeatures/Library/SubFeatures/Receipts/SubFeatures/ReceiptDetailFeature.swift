//
//  ReceiptDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ReceiptDetailFeature {
    @ObservableState
    struct State: Equatable {
        let id: UUID
        @Presents var alert: AlertState<ReceiptDetailFeature.Action.Alert>?
    }

    enum Action: Equatable {
        case deleteButtonTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        enum Alert: Equatable {
            case confirmDeletion
        }

        enum Delegate: Equatable {
            case deleteReceipt(UUID)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                case .deleteButtonTapped:
                    state.alert = AlertState {
                        TextState("Are you sure?")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDeletion) {
                            TextState("Delete")
                        }
                    }
                    return .none
                case .alert(.presented(.confirmDeletion)):
                    state.alert = nil
                    return .run {
                        [id = state.id] send in
                        await send(.delegate(.deleteReceipt(id)))
                    }
                case .alert:
                    return .none
                case .delegate:
                    return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }
}
