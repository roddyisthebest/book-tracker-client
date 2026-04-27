//
//  BookInfoFeature.swift
//  BookTracker
//
//  Created by 배성연 on 4/27/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct BookInfoFeature {
    @Dependency(\.externalBookService) var externalBookService

    @ObservableState
    struct State: Equatable {
        let externalBookId: String
        var externalBook: ExternalBook?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case fetchResponse(Result<ExternalBook, ExternalBookService.ServiceError>)
        case retryButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [id = state.externalBookId] send in
                    let result = try await externalBookService.detail(id)
                    await send(.fetchResponse(result))
                }

            case let .fetchResponse(.success(book)):
                state.isLoading = false
                state.externalBook = book
                return .none

            case let .fetchResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .retryButtonTapped:
                return .send(.onAppear)
            }
        }
    }
}
