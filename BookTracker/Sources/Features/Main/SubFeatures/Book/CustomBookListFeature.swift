//
//  CustomBookListFeature.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CustomBookListFeature {
    @Dependency(\.localCustomBookService) var localCustomBookService
    @Shared(.userId) var userId: String?

    @ObservableState
    struct State: Equatable {
        var books: [ExternalBook] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
    }

    enum Action: Equatable {
        case onAppear
        case loadResponse(Result<[ExternalBook], LocalCustomBookError>)
        case deleteTapped(id: String)
        case deleteResponse(Result<String, LocalCustomBookError>)
        case clearAllTapped
        case clearAllResponse(Result<Bool, LocalCustomBookError>)
        case bookTapped(ExternalBook)

        case delegate(Delegate)
        enum Delegate: Equatable {
            case openBook(ExternalBook)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                let userId = userId ?? ""
                return .run { send in
                    let result = await localCustomBookService.fetchAll(userId)
                    await send(.loadResponse(result))
                }

            case .loadResponse(.success(let books)):
                state.isLoading = false
                state.books = books
                state.errorMessage = nil
                return .none

            case .loadResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .deleteTapped(let id):
                state.books.removeAll { $0.id == id }
                let userId = userId ?? ""
                return .run { send in
                    let result = await localCustomBookService.remove(id, userId)
                    await send(.deleteResponse(result))
                }

            case .deleteResponse:
                return .none

            case .clearAllTapped:
                let userId = userId ?? ""
                return .run { send in
                    let result = await localCustomBookService.clearAll(userId)
                    switch result {
                    case .success:
                        await send(.clearAllResponse(.success(true)))
                    case .failure(let error):
                        await send(.clearAllResponse(.failure(error)))
                    }
                }

            case .clearAllResponse(.success):
                state.books = []
                return .none

            case .clearAllResponse(.failure):
                return .none

            case .bookTapped(let book):
                return .send(.delegate(.openBook(book)))

            case .delegate:
                return .none
            }
        }
    }
}
