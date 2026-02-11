//
//  CollectionDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/9/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CollectionDetailFeature {
    @ObservableState
    struct State: Equatable {
        var books: [Book] = [
            Book(id: UUID(1), title: "스위프트 마스터 1", author: "저자 A", publisher: "출판사 A", imageUrl: nil, isbn: "111-1111111111", stereo: .done),
            Book(id: UUID(2), title: "스위프트 마스터 2", author: "저자 B", publisher: "출판사 B", imageUrl: nil, isbn: "222-2222222222", stereo: .reading),
            Book(id: UUID(3), title: "스위프트 마스터 3", author: "저자 C", publisher: "출판사 C", imageUrl: nil, isbn: "333-3333333333", stereo: .done),
            Book(id: UUID(4), title: "스위프트 마스터 4", author: "저자 D", publisher: "출판사 D", imageUrl: nil, isbn: "444-4444444444", stereo: .reading),
            Book(id: UUID(5), title: "스위프트 마스터 5", author: "저자 E", publisher: "출판사 E", imageUrl: nil, isbn: "555-5555555555", stereo: .done),
            Book(id: UUID(6), title: "스위프트 마스터 6", author: "저자 F", publisher: "출판사 F", imageUrl: nil, isbn: "666-6666666666", stereo: .reading),
            Book(id: UUID(7), title: "스위프트 마스터 7", author: "저자 G", publisher: "출판사 G", imageUrl: nil, isbn: "777-7777777777", stereo: .done),
            Book(id: UUID(8), title: "스위프트 마스터 8", author: "저자 H", publisher: "출판사 H", imageUrl: nil, isbn: "888-8888888888", stereo: .reading),
            Book(id: UUID(9), title: "스위프트 마스터 9", author: "저자 I", publisher: "출판사 I", imageUrl: nil, isbn: "999-9999999999", stereo: .done),
            Book(id: UUID(10), title: "스위프트 마스터 10", author: "저자 J", publisher: "출판사 J", imageUrl: nil, isbn: "000-0000000000", stereo: .reading)
        ]
        var sortOption: BookSortOption = .newest
        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case editButtonTapped(EditButtonKind)
        case bookCardTapped(UUID)
        case deleteButtonTapped(UUID)

        case destination(PresentationAction<Destination.Action>)

        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
        }

        enum EditButtonKind: Equatable {
            case books
            case collection
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce {
            state, action in
            switch action {
            case .editButtonTapped(.books):
                state.destination = .selectBooks(CollectionSelectBooksFeature.State())
                return .none
            case .editButtonTapped(.collection):
                state.destination = .formCollection(CollectionFormFeature.State())
                return .none
            case .bookCardTapped:
                return .none
            case .deleteButtonTapped(let id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none
            case .destination(.presented(.selectBooks(.delegate(.updateCollection)))):
                // Dismiss selectBooks and update books when collection updates
                state.destination = nil
                // TODO: Update state.books based on selection
                return .none
            case .destination(.presented(.alert(.confirmDeletion))):
                return .none
            case .destination:
                return .none
            case .binding:
                return .none
            }
        }.ifLet(\.$destination, action: \.destination)
    }
}

extension CollectionDetailFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case selectBooks(CollectionSelectBooksFeature)
        case formCollection(CollectionFormFeature)
        case alert(AlertState<CollectionDetailFeature.Action.Alert>)
    }
}

extension AlertState where Action == CollectionDetailFeature.Action.Alert {
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
