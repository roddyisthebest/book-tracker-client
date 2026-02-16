//
//  MyBooksFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/15/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct MyBookListFeature {
    @ObservableState
    struct State: Equatable {
        var books: [Book] = [
            Book(id: UUID(1), title: "as", author: "asdf", publisher: "vvas", imageUrl: nil, isbn: "asddfqweew", status: .done, type: .ebook),
            Book(id: UUID(2), title: "as2", author: "asdf", publisher: "vvas", imageUrl: nil, isbn: "asddfqweew", status: .dropped, type: .ebook),
            Book(id: UUID(3), title: "as3", author: "asdf", publisher: "vvas", imageUrl: nil, isbn: "asddfqweew", status: .reading, type: .paper),
            Book(id: UUID(4), title: "as4", author: "asdf", publisher: "vvas", imageUrl: nil, isbn: "asddfqweew", status: .want, type: .paper),
        ]
        var bookStatus: BookStatus = .done
        var sortOption: BookSortOption = .newest

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case bookCardTapped(id: UUID)
        case deleteButtonTapped(id: UUID)
        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> {
            state, action in
            switch action {
            case .bookCardTapped(let id):
                state.destination = .viewBookDetail(BookDetailFeature.State())
                return .none
            case .deleteButtonTapped(let id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case .destination(.presented(.alert(.confirmDeletion))):
                return .none
            case .destination(.dismiss):
                print("뒤로왓으요")
                return .none
            case .destination:
                return .none
            case .binding:
                return .none
            case .binding(\.bookStatus):
                print(state.bookStatus, "book-status")
                return .none
            case .binding(\.sortOption):
                print(state.sortOption, "sort-option")
                return .none
            }
        }.ifLet(\.$destination, action: \.destination)
    }
}

extension MyBookListFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case viewBookDetail(BookDetailFeature)
        case alert(AlertState<MyBookListFeature.Action.Alert>)
    }
}

extension AlertState where Action == MyBookListFeature.Action.Alert {
    static func deleteConfirmation(id: UUID) -> Self {
        Self {
            TextState("Are you sure?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                TextState("Delete")
            }
        }
    }
}
