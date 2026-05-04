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
    @Dependency(\.localReceiptService) var localReceiptService
    @Shared(.userId) var userId: String?

    @ObservableState
    struct State: Equatable {
        var type: ReceiptType = .purchase

        var books: [ReceiptBook] = []

        var isFetching: Bool = false
        var isError: Bool = false

        var isDeleting: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case onAppear
        case onRefresh
        case loadBooks
        case loadBooksResponse(Result<[ReceiptBook], LocalReceiptError>)

        case addButtonTapped

        case deleteButtonTapped(id: String)
        case deleteBookResponse(Result<String, LocalReceiptError>)

        case issueButtonTapped

        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case receiptFlowCompleted(type: ReceiptType)
            case removeBook(id: String, type: ReceiptType)
        }

        enum Alert: Equatable {}
    }

    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case .onRefresh:
                return .send(.onAppear)
            case .onAppear:
                return .send(.loadBooks)
            case .loadBooks:
                state.isFetching = true
                state.isError = false
                let userId = userId ?? ""
                return .run {
                    [type = state.type] send in
                    let result = await localReceiptService.fetchBooks(userId, type)
                    await send(.loadBooksResponse(result))
                }
            case .loadBooksResponse(.success(let books)):
                state.isFetching = false
                state.books = books
                return .none
            case .loadBooksResponse(.failure):
                state.isFetching = false
                state.isError = true
                return .none
            case .addButtonTapped:
                state.destination = .search(SearchFeature.State())
                return .none
            case .deleteButtonTapped(let id):
                state.isDeleting = true
                let userId = userId ?? ""
                return .run {
                    [type = state.type] send in
                    let result = await localReceiptService.remove(userId, id, type)
                    await send(.deleteBookResponse(result))
                }
            case .deleteBookResponse(.success(let id)):
                state.isDeleting = false
                guard let book = state.books.first(where: { $0.id == id })
                else {
                    return .none
                }
                state.books.removeAll { $0.id == book.id }
                return .send(.delegate(.removeBook(id: book.id, type: book.type)))
            case .deleteBookResponse(.failure):
                state.isDeleting = false
                state.destination = .alert(.showDeletionErrorAlert())
                return .none
            case .issueButtonTapped:
                state.destination = .issueReceipt(IssueReceiptFeature.State(receiptBooks: state.books, type: state.type))
                return .none
            case .destination(.presented(.issueReceipt(.delegate(.issueReceiptCompleted)))):
                state.destination = nil
                state.books = []
                let type = state.type
                return .run {
                    send in
                    await send(.delegate(.receiptFlowCompleted(type: type)))
                }
            case .destination(.presented(.search(.detailSheet(.presented(.delegate(.addBookToReceipt(let book, let type))))))):
                if type == state.type {
                    state.books.append(book)
                }
                return .none
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

extension AlertState where Action == ReceiptSelectBooksFeature.Action.Alert {
    static func showDeletionErrorAlert() -> Self {
        Self {
            TextState("book_delete_failed")
        }
    }
}
