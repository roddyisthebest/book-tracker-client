//
//  HomeFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/19/26.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var books: [Book] = []

        var receiptBookCount: Int = 0
        var rentalBookCount: Int = 0

        var hasDone: Bool = false

        var path = StackState<Path.State>()

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case doneButtonTapped
        case bookSectionTapped(status: BookStatus)
        case receiptIssueButtonTapped(type: ReceiptType)
        case myBooksButtonTapped

        case path(StackAction<Path.State, Path.Action>)
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .doneButtonTapped:
                return .none
            case .bookSectionTapped(let status):
                state.path.append(.myBooks(MyBookListFeature.State(bookStatus: status)))
                return .none
            case .receiptIssueButtonTapped(let type):
                state.destination = .selectBooks(ReceiptSelectBooksFeature.State())
                return .none
            case .myBooksButtonTapped:
                state.path.append(.myBooks(MyBookListFeature.State()))
                return .none
            case .destination(.presented(.selectBooks(.delegate(.receiptFlowCompleted)))):
                state.destination = nil
                return .none
            case .path:
                return .none
            case .destination:
                return .none
            }
        }

        .forEach(\.path, action: \.path) {
            Path()
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension HomeFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case myBooks(MyBookListFeature.State = .init())
        }

        enum Action: Equatable {
            case myBooks(MyBookListFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.myBooks, action: \.myBooks) {
                MyBookListFeature()
            }
        }
    }
}

extension HomeFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case selectBooks(ReceiptSelectBooksFeature)
    }
}
