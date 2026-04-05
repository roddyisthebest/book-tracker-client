//
//  CollectionAddBooksFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/9/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AddBooksFeature {
    @Dependency(\.bookService) var bookService

    @ObservableState
    struct State: Equatable {
        var books: [Book] = []
        var selectedIds: Set<UUID> = []
        var unSelectableIds: Set<UUID> = []

        var keyword: String = ""

        var isLoading: Bool = false
        var isLoadingMore: Bool = false
        var errorMessage: String? = nil

        var nextIndex: Int = 0
        var pageSize: Int = 20
        var hasMore: Bool = true
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)

        case onAppear

        case loadBooks
        case loadBooksResponse(Result<[Book], AppError>)

        case loadMore
        case loadMoreResponse(Result<[Book], AppError>)

        case refresh

        case bookSelected(UUID)
        case delegate(Delegate)
        case addButtonTapped
        enum Delegate: Equatable {
            case addBooksToCollection([Book])
        }
    }

    private enum CancelID {
        case loadBooks
        case loadMore
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadBooks)
            case .loadBooks:
                state.isLoading = true
                state.errorMessage = nil
                state.nextIndex = 0
                state.hasMore = true

                let pageSize = state.pageSize

                return .merge(
                    .cancel(id: CancelID.loadMore),
                    .run { send in
                        let result = try await bookService.list(nil, pageSize, 0)
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

                let pageSize = state.pageSize
                let nextIndex = state.nextIndex

                return .run { send in
                    let result = try await bookService.list(nil, pageSize, nextIndex)
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
            case .bookSelected(let id):
                let isSelected = state.selectedIds.contains(id)
                if isSelected {
                    state.selectedIds.remove(id)
                }
                else {
                    state.selectedIds.insert(id)
                }
                return .none
            case .addButtonTapped:
                return .send(.delegate(.addBooksToCollection(state.selectedBooks)))
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

extension AddBooksFeature.State {
    var filteredBooks: [Book] {
        books.filter {
            if keyword.isEmpty {
                return true
            }

            return $0.title.contains(keyword) || $0.author.contains(keyword)
        }
    }

    var selectedBooks: [Book] {
        books.filter { selectedIds.contains($0.id) }
    }

    var isSubmitEnabled: Bool {
        selectedIds.count > 0
    }
}
