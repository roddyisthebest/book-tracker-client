//
//  ReceiptSelectBooksFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ReceiptSelectBooksFeature {
    @ObservableState
    struct State: Equatable {
        var externalBooks: [ExternalBook] = [
            ExternalBook(id: "1", title: "asdfdsfsdfdsfd")
        ]

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case addButtonTapped
        case deleteButtonTapped(id: String)
        case issueButtonTapped

        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case receiptFlowCompleted
        }

        enum Alert {
            case confirmDeletion
        }
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case .addButtonTapped:
                state.destination = .search(SearchFeature.State())
                return .none
            case .deleteButtonTapped(let id):
                state.externalBooks.removeAll { $0.id == id }
                return .none
            case .issueButtonTapped:
                state.destination = .issueReceipt(IssueReceiptFeature.State())
                return .none
            case .destination(.presented(.issueReceipt(.delegate(.issueReceiptCompleted)))):
                state.destination = nil
                return .run {
                    send in
                    await send(.delegate(.receiptFlowCompleted))
                }
            case .destination:
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension ReceiptSelectBooksFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case issueReceipt(IssueReceiptFeature)
        case search(SearchFeature)
        case alert(AlertState<ReceiptSelectBooksFeature.Action.Alert>)
    }
}
