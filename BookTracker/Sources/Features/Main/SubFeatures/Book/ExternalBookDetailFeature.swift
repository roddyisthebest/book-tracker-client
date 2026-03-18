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
    @Dependency(\.externalBookService) var bookService
    @Dependency(\.bookService) var myBookService

    @ObservableState
    struct State: Equatable {
        let id: String
        var book: ExternalBook? = nil
        var isAlreadyRegistered: Bool? = nil

        var isLoading: Bool = false
        var errorMessage: String? = nil

        var isExtended: Bool = false
        var isExtendable: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        enum AddType: Equatable {
            case receipt
            case rental
            case mybooks(externalId: String)
        }

        case load
        case detailResponse(Result<ExternalBook, ExternalBookService.ServiceError>)
        case alreadyRegisteredResponse(Result<Bool, AppError>)
        case addButtonTapped(AddType)
        case extendButtonTapped

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmReceipt
            case confirmRental
        }

        case delegate(Delegate)
        enum Delegate: Equatable {
            case addBookToReceipt(book: ExternalBook)
            case addBookToRental(book: ExternalBook)
        }
    }

    private enum CancelID { case fetch, check }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .load:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [id = state.id] send in
                    let result = try await bookService.detail(id)
                    await send(.detailResponse(result))
                }
                .cancellable(id: CancelID.fetch, cancelInFlight: true)
            case .detailResponse(.success(let book)):
                state.isLoading = false
                state.errorMessage = nil
                state.book = book
                return .run { [externalId = state.id] send in
                    let result = try await myBookService.isAlreadyRegistered(externalId)
                    await send(.alreadyRegisteredResponse(result))
                }
                .cancellable(id: CancelID.check, cancelInFlight: true)
            case .detailResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case .alreadyRegisteredResponse(.success(let exists)):
                state.isAlreadyRegistered = exists
                return .none
            case .alreadyRegisteredResponse(.failure(let error)):
                state.errorMessage = error.localizedDescription
                state.isAlreadyRegistered = nil
                return .none
            case .addButtonTapped(.mybooks(let externalId)):
                if let exists = state.isAlreadyRegistered {
                    if exists {
                        state.destination = .alert(.alreadyRegistered())
                        return .none
                    } else {
                        guard let book = state.book else {
                            return .none
                        }

                        state.destination = .formBook(BookFormFeature.State(externalId: externalId, externalBook: book))
                        return .none
                    }
                } else {
                    // Registration status unknown; do nothing or trigger re-check if desired
                    return .none
                }
            case .addButtonTapped(.receipt):
                state.destination = .alert(.receiptConfirmation())
                guard let book = state.book else {
                    return .none
                }
                return .send(.delegate(.addBookToReceipt(book: book)))
            case .addButtonTapped(.rental):
                state.destination = .alert(.rentalConfirmation())
                guard let book = state.book else {
                    return .none
                }

                return .send(.delegate(.addBookToRental(book: book)))
            case .extendButtonTapped:
                state.isExtended.toggle()
                return .none
            case .destination(.presented(.alert(.confirmReceipt))):
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

    static func alreadyRegistered() -> Self {
        Self {
            TextState("이미 등록된 책입니다.")
        } actions: {}
    }
}
