//
//  BookDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/13/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct BookDetailFeature {
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        var id: UUID?

        var book: Book?
        @Presents var destination: Destination.State?
        var isLoading: Bool = false
        var isDeleting: Bool = false
        var errorMessage: String? = nil
    }

    enum Action: Equatable {
        case deleteButtonTapped
        case updateButtonTapped
        case moreButtonTapped

        case changeStatusButtonTapped(BookStatus)

        case onAppear
        case fetch
        case fetchResponse(Result<Book, AppError>)
        case deletionResponse(Result<UUID, AppError>)
        case statusUpdateButtonTapped(StatusEditButtonKind)
        enum StatusEditButtonKind: Equatable {
            case done
            case dropped
            case returned
            case reading
        }

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmDeletion
            case retryFetch
        }

        case delegate(Delegate)
        enum Delegate: Equatable {
            case confirmDeletion(deleted: UUID)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .deleteButtonTapped:
                state.destination = .alert(.deleteConfirmation())
                return .none

            case .updateButtonTapped:
                guard
                    let book = state.book,
                    let externalBookId = book.externalBookId
                else {
                    state.destination = .alert(.showUpdateAccessDeniedAlert())
                    return .none
                }

                state.destination = .formBook(BookFormFeature.State(externalId: externalBookId, bookId: book.id, book: book, changeMode: nil))
                return .none

            case let .changeStatusButtonTapped(bookStatus):
                guard
                    let book = state.book,
                    let externalBookId = book.externalBookId
                else {
                    state.destination = .alert(.showUpdateAccessDeniedAlert())
                    return .none
                }

                state.destination = .formBook(BookFormFeature.State(externalId: externalBookId, bookId: book.id, book: book, changeMode: bookStatus))
                return .none

            case .moreButtonTapped:
                return .none

            case .onAppear:
                return .send(.fetch)

            case .fetch:
                guard let id = state.id else {
                    state.isLoading = false
                    state.errorMessage = "잘못된 요청입니다. 책 ID가 없습니다."
                    return .none
                }
                state.isLoading = true
                state.errorMessage = nil
                let service = self.bookService
                return .run { [id] send in
                    let result = try await service.fetch(id)
                    await send(.fetchResponse(result))
                }

            case let .fetchResponse(.success(book)):
                state.isLoading = false
                state.book = book
                return .none

            case let .fetchResponse(.failure(error)):
                state.isLoading = false
                switch error {
                case let .auth(code, status, message):
                    state.errorMessage = message
                case let .function(_, message):
                    state.errorMessage = message
                case let .network(message):
                    state.errorMessage = message
                case let .storage(_, _, message):
                    state.errorMessage = message
                case .unauthorized:
                    state.errorMessage = "Unauthorized"
                case .rateLimited:
                    state.errorMessage = "Rate limited"
                default:
                    state.errorMessage = "Unknown error"
                }
                state.errorMessage = error.localizedDescription
                return .none

            case let .deletionResponse(result):
                state.isDeleting = false
                switch result {
                case .success:
                    guard let id = state.id else {
                        return .none
                    }
                    return .run {
                        [id = id] send in
                        await send(.delegate(.confirmDeletion(deleted: id)))
                    }
                case .failure:
                    state.destination = .alert(.showDeletionErrorAlert())
                    return .none
                }

            case .statusUpdateButtonTapped(.done):
                return .none

            case .statusUpdateButtonTapped:
                return .none

            case .destination(.presented(.alert(.confirmDeletion))):
                guard let id = state.id else { return .none }
                state.isDeleting = true
                return .run {
                    [id = id] send in
                    let result = try await self.bookService.delete(id)
                    await send(.deletionResponse(result))
                }

            case .destination(.presented(.alert(.retryFetch))):
                return .send(.fetch)

            case let .destination(.presented(.formBook(.delegate(.confirmUpdate(updated))))):
                state.destination = nil
                state.book = updated
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

extension BookDetailFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case formBook(BookFormFeature)
        case alert(AlertState<BookDetailFeature.Action.Alert>)
    }
}

extension AlertState where Action == BookDetailFeature.Action.Alert {
    static func deleteConfirmation() -> Self {
        Self {
            TextState("Are you sure?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion) {
                TextState("Delete")
            }
        }
    }

    static func showUpdateAccessDeniedAlert() -> Self {
        Self {
            TextState("You don't have permission to update this book.")
        }
    }

    static func showDeletionErrorAlert() -> Self {
        Self {
            TextState("Failed to delete the book.")
        }
    }
}
