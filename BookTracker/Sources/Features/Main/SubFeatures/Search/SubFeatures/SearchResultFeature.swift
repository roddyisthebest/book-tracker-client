//
//  SearchResultFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchResultFeature {
    @ObservableState
    struct State: Equatable {
        var externalBooks: [ExternalBook] = []
        var keyword: String = ""
        var isLoading: Bool = false
        var errorMessage: String? = nil
        var nextIndex: Int = 0
        var pageSize: Int = 20
        var isLoadingMore: Bool = false
        var hasMore: Bool = true
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case setKeyword(String)
        case searchResponse(Result<[ExternalBook], ExternalBookService.ServiceError>)
        case externalBookTapped(id: String)
        case loadMore
        case loadMoreResponse(Result<[ExternalBook], ExternalBookService.ServiceError>)
        case cancelSearch
        case refresh
        case alert(PresentationAction<Alert>)

        case delegate(Delegate)

        enum Delegate: Equatable {
            case tapBook(id: String)
        }

        enum Alert: Equatable {
            case dismiss
        }
    }

    @Dependency(\.externalBookService) var bookService
    @Dependency(\.continuousClock) var clock
    @Dependency(\.searchHistory) var searchHistory
    @Dependency(\.date) var date
    private enum CancelID { case search, loadMore }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .setKeyword(let k):
                state.keyword = k
                let trimmed = k.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    state.isLoading = false
                    state.nextIndex = 0
                    state.isLoadingMore = false
                    state.hasMore = true
                    state.errorMessage = nil
                    state.externalBooks = []
                    return .merge(
                        .cancel(id: CancelID.search),
                        .cancel(id: CancelID.loadMore)
                    )
                }
                state.isLoading = true
                state.isLoadingMore = false
                state.errorMessage = nil
                state.nextIndex = 0
                state.hasMore = true
                return .merge(
                    .cancel(id: CancelID.loadMore),
                    .run { [pageSize = state.pageSize] send in
                        try await clock.sleep(for: .milliseconds(200))
                        let result = try await bookService.search(trimmed, 0, pageSize)
                        await send(.searchResponse(result))
                    }
                    .cancellable(id: CancelID.search, cancelInFlight: true)
                )

            case .cancelSearch:
                state.isLoading = false
                state.isLoadingMore = false
                state.errorMessage = nil
                state.externalBooks = []
                state.nextIndex = 0
                state.hasMore = true
                return .merge(
                    .cancel(id: CancelID.search),
                    .cancel(id: CancelID.loadMore)
                )

            case .refresh:
                let trimmed = state.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    return .none
                }
                // Keep current list, but restart the first page request
                state.isLoading = true
                state.errorMessage = nil
                state.nextIndex = 0
                state.hasMore = true
                return .merge(
                    .cancel(id: CancelID.loadMore),
                    .run { [pageSize = state.pageSize] send in
                        try await clock.sleep(for: .milliseconds(200))
                        let result = try await bookService.search(trimmed, 0, pageSize)
                        await send(.searchResponse(result))
                    }
                    .cancellable(id: CancelID.search, cancelInFlight: true)
                )

            case .searchResponse(.success(let books)):
                state.isLoading = false
                state.externalBooks = books
                state.nextIndex = books.count
                state.hasMore = books.count == state.pageSize
                return .none

            case .searchResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                state.externalBooks = []
                state.alert = AlertState {
                    TextState("문제가 발생했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .loadMore:
                // Guard conditions: not already loading, has keyword, has more pages
                let trimmed = state.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if state.isLoading || state.isLoadingMore || trimmed.isEmpty || !state.hasMore {
                    return .none
                }
                state.isLoadingMore = true
                return .run { [keyword = trimmed, start = state.nextIndex, size = state.pageSize] send in
                    let result = try await bookService.search(keyword, start, size)
                    await send(.loadMoreResponse(result))
                }
                .cancellable(id: CancelID.loadMore, cancelInFlight: true)

            case .loadMoreResponse(.success(let books)):
                state.isLoadingMore = false
                state.externalBooks.append(contentsOf: books)
                state.nextIndex += books.count
                state.hasMore = books.count == state.pageSize
                return .none

            case .loadMoreResponse(.failure(let error)):
                state.isLoadingMore = false
                state.errorMessage = error.localizedDescription
                state.alert = AlertState {
                    TextState("추가 로딩에 실패했어요")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                } message: {
                    TextState(error.localizedDescription)
                }
                // Keep hasMore as is to allow retry
                return .none

            case .externalBookTapped(let id):
                guard let book = state.externalBooks.first(where: { $0.id == id }) else {
                    return .none
                }
                let trimmed = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
                return .merge(
                    .send(.delegate(.tapBook(id: id))),
                    .run { [searchHistory, date, trimmed] _ in
                        guard !trimmed.isEmpty else { return }
                        try await searchHistory.add(trimmed, date())
                    }
                )

            case .delegate:
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
