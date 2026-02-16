//
//  LibraryFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/15/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LibraryFeature {
    @ObservableState
    struct State: Equatable {
        var collections: [Collection] = [
            Collection(id: UUID(1), isDefault: false, title: "as", description: "fasds"),
            Collection(id: UUID(2), isDefault: false, title: "as", description: "fasds"),
            Collection(id: UUID(3), isDefault: false, title: "as", description: "fasds")
        ]
        var receipts: [Receipt] = [
            Receipt(id: UUID(1), type: .purchase, title: "alsdkkks"),
            Receipt(id: UUID(2), type: .rental, title: "2asds")
        ]

        var path = StackState<Path.State>()

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case sectionTapped(Section)
        case path(StackAction<Path.State, Path.Action>)

        case collectionCardTapped(id: UUID)
        case receiptCardTapped(id: UUID)

        case destination(PresentationAction<Destination.Action>)

        enum Section: Equatable {
            case myBooks(status: BookStatus)
            case collections
            case receipts
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .collectionCardTapped(let id):
                state.destination = .collectionDetail(CollectionDetailFeature.State())
                return .none
            case .receiptCardTapped(let id):
                state.destination = .receiptDetail(ReceiptDetailFeature.State(id: id))
                return .none
            case .sectionTapped(.collections):
                state.path.append(.collections(CollectionListFeature.State()))
                return .none
            case .sectionTapped(.myBooks(let status)):
                state.path.append(.myBooks(MyBookListFeature.State(bookStatus: status)))
                return .none
            case .sectionTapped(.receipts):
                state.path.append(.receipts(ReceiptListFeature.State()))
                return .none
            case .destination:
                return .none
            case .path:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path) {
            Path()
        }
    }
}

extension LibraryFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case myBooks(MyBookListFeature.State = .init())
            case receipts(ReceiptListFeature.State = .init())
            case collections(CollectionListFeature.State = .init())
        }

        enum Action: Equatable {
            case myBooks(MyBookListFeature.Action)
            case receipts(ReceiptListFeature.Action)
            case collections(CollectionListFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.myBooks, action: \.myBooks) {
                MyBookListFeature()
            }
            Scope(state: \.receipts, action: \.receipts) {
                ReceiptListFeature()
            }
            Scope(state: \.collections, action: \.collections) {
                CollectionListFeature()
            }
        }
    }
}

extension LibraryFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case collectionDetail(CollectionDetailFeature)
        case receiptDetail(ReceiptDetailFeature)
    }
}
