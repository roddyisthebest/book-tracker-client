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
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        var books: [Book] = []
        var bookStatus: BookStatus = .done
        var sortOption: BookSortOption = .newest

        var statusCounts: [BookStatus: Int]? = nil
        var isLoadingStatusCounts: Bool = false

        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var errorMessage: String? = nil

        var nextIndex: Int = 0
        var pageSize: Int = 20
        var hasMore: Bool = true

        var isDeleting: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case onAppear

        case loadBooks
        case loadBooksResponse(Result<[Book], AppError>)

        case loadMore
        case loadMoreResponse(Result<[Book], AppError>)

        case refresh

        case loadStatusCounts
        case statusCountsResponse(Result<[BookStatus: Int], AppError>)

        case bookCardTapped(id: UUID)
        case deleteButtonTapped(id: UUID)

        case deletionResponse(result: Result<UUID, AppError>)

        case destination(PresentationAction<Destination.Action>)

        enum Alert: Equatable {
            case confirmDeletion(id: UUID)
        }
    }

    private enum CancelID {
        case loadBooks
        case loadMore
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadStatusCounts),
                    .send(.loadBooks)
                )

            case .loadBooks:
                state.isLoading = true
                state.errorMessage = nil
                state.nextIndex = 0
                state.hasMore = true

                let status = state.bookStatus
                let pageSize = state.pageSize

                return .merge(
                    .cancel(id: CancelID.loadMore),
                    .run { send in
                        let result = try await bookService.list(status, pageSize, 0)
                        await send(.loadBooksResponse(result))
                    }
                    .cancellable(id: CancelID.loadBooks, cancelInFlight: true)
                )

            case .loadBooksResponse(.success(let books)):
                state.isLoading = false
                state.books = books
                state.nextIndex = books.count
                state.hasMore = books.count == state.pageSize
                return .none

            case .loadBooksResponse(.failure(let error)):
                state.isLoading = false
                state.books = []
                state.errorMessage = error.localizedDescription
                state.nextIndex = 0
                state.hasMore = false
                return .none

            case .loadMore:
                guard !state.isLoading,
                      !state.isLoadingMore,
                      state.hasMore
                else {
                    return .none
                }

                state.isLoadingMore = true

                let status = state.bookStatus
                let pageSize = state.pageSize
                let nextIndex = state.nextIndex

                return .run { send in
                    let result = try await bookService.list(status, pageSize, nextIndex)
                    await send(.loadMoreResponse(result))
                }
                .cancellable(id: CancelID.loadMore, cancelInFlight: true)

            case .loadMoreResponse(.success(let books)):
                state.isLoadingMore = false
                state.books.append(contentsOf: books)
                state.nextIndex += books.count
                state.hasMore = books.count == state.pageSize
                return .none

            case .loadMoreResponse(.failure(let error)):
                state.isLoadingMore = false
                state.errorMessage = error.localizedDescription
                return .none

            case .refresh:
                return .send(.loadBooks)

            case .loadStatusCounts:
                state.isLoadingStatusCounts = true
                return .run { send in
                    let result = try await bookService.statusCounts()
                    await send(.statusCountsResponse(result))
                }

            case .statusCountsResponse(let result):
                state.isLoadingStatusCounts = false
                switch result {
                case .success(let counts):
                    state.statusCounts = counts
                case .failure:
                    state.statusCounts = nil
                }
                return .none

            case .bookCardTapped(let id):
                state.destination = .viewBookDetail(BookDetailFeature.State(id: id))
                return .none

            case .deleteButtonTapped(let id):
                state.destination = .alert(.deleteConfirmation(id: id))
                return .none

            case .destination(.presented(.alert(.confirmDeletion(let id)))):
                state.isDeleting = true
                return .run {
                    [id = id] send in
                    let result = try await bookService.delete(id)
                    await send(.deletionResponse(result: result))
                }

            case .destination(.presented(.viewBookDetail(.delegate(.confirmDeletion(let deletedId))))):
                state.destination = nil
                guard let deleted = state.books.first(where: { book in
                    book.id == deletedId
                }) else {
                    return .none
                }

                state.books = state.books.filter { $0.id != deleted.id }
                // Ensure dictionary exists
                if state.statusCounts == nil {
                    state.statusCounts = [:]
                }

                state.statusCounts![deleted.status, default: 0] = max(0, state.statusCounts![deleted.status, default: 0] - 1)

                return .none

            case .destination(.presented(.viewBookDetail(.destination(.presented(.formBook(.delegate(.confirmUpdate))))))):
                return .run { send in
                    await send(.onAppear)
                }

            case .deletionResponse(let result):
                state.isDeleting = false
                switch result {
                case .success(let id):
                    guard let deleted = state.books.first(where: { book in
                        book.id == id
                    }) else {
                        return .none
                    }
                    state.books = state.books.filter { $0.id != deleted.id }
                    // Ensure dictionary exists
                    if state.statusCounts == nil {
                        state.statusCounts = [:]
                    }

                    state.statusCounts![deleted.status, default: 0] = max(0, state.statusCounts![deleted.status, default: 0] - 1)
                    return .none
                case .failure:
                    state.destination = .alert(.showDeletionErrorAlert())
                    return .none
                }

            case .destination(.dismiss):
                return .none

            case .destination:
                return .none

            case .binding(\.bookStatus):
                state.books = []
                state.nextIndex = 0
                state.hasMore = true
                return .send(.loadBooks)

            case .binding(\.sortOption):
                return .none

            case .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
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

    static func showDeletionErrorAlert() -> Self {
        Self {
            TextState("Failed to delete the book.")
        }
    }
}
