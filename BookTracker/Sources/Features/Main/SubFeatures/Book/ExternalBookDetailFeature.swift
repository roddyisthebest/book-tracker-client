//
//  ExternalBookDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ExternalBookDetailFeature {
    @ObservableState
    struct State: Equatable {
        var book: ExternalBook?

        var isExtended: Bool = false
        var isExtendable: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        enum AddType: Equatable {
            case receipt
            case rental
            case mybooks
        }

        case addButtonTapped(AddType)
        case extendButtonTapped

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmReceipt
            case confirmRental
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .addButtonTapped(.mybooks):
                state.destination = .formBook(BookFormFeature.State(externalId: "as", bookId: UUID(1)))
                return .none
            case .addButtonTapped(.receipt):
                state.destination = .alert(.receiptConfirmation())
                return .none
            case .addButtonTapped(.rental):
                state.destination = .alert(.rentalConfirmation())
                return .none
            case .extendButtonTapped:
                state.isExtended.toggle()
                return .none
            case .destination(.presented(.alert(.confirmReceipt))):
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension ExternalBookDetailFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case formBook(BookFormFeature)
        case alert(AlertState<ExternalBookDetailFeature.Action.Alert>)
    }
}

extension AlertState where Action == ExternalBookDetailFeature.Action.Alert {
    static func receiptConfirmation() -> Self {
        Self {
            TextState("영수증에 추가되었습니다.")
        } actions: {}
    }

    static func rentalConfirmation() -> Self {
        Self {
            TextState("대출증에 추가되었습니다.")
        } actions: {}
    }
}
