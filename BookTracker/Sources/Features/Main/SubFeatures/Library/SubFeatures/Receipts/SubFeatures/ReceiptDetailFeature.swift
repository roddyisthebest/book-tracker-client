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
        let recepit: String
        @Presents var alert: AlertState<ReceiptDetailFeature.Action.Alert>?
    }

    enum Action: Equatable {
        case deleteButtonTapped(id: UUID)
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
            case confirmSuccession
        }
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                case .deleteButtonTapped(let id):
                    state.alert = AlertState {
                        TextState("Are you sure?")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                            TextState("Delete")
                        }
                    }
                    return .none
                case .alert(.presented(.confirmDeletion(let id))):
                    state.alert = AlertState {
                        TextState("successfully deleted")
                    } actions: {
                        ButtonState(role: .cancel, action: .confirmSuccession) {
                            TextState("Confirm")
                        }
                    }
                    return .none
                case .alert(.presented(.confirmSuccession)):
                    return .run { _ in
                        await dismiss()
                    }
                case .alert:
                    return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }
}
