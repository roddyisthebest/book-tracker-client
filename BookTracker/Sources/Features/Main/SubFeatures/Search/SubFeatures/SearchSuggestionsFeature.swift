//
//  SearchSuggestionsFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SearchSuggestionsFeature {
    @Dependency(\.searchHistory) var searchHistory
    @Dependency(\.searchKeywordService) var searchKeywordService

    @Dependency(\.date) var date

    @ObservableState
    struct State: Equatable {
        var searchKeywordsResult: Result<[SearchKeyword], AppError> = .success([])
        var searchesResult: Result<[Search], AppError> = .success([])

        var isSearchKeywordsLoading: Bool = false

        var isSearchesLoading: Bool = false
    }

    enum Action: Equatable {
        case searchTapped(text: String)
        case deleteButtonTapped(id: String)
        case onAppear
        case cancelLoading

        case loadSearchKeyword
        case loadSearchKeywordResponse(Result<[SearchKeyword], AppError>)

        case loadRecents
        case loadRecentsResponse(Result<[Search], AppError>)

        case delegate(Delegate)
        enum Delegate: Equatable {
            case setKeyword(String)
        }
    }

    private enum CancelID { case loadKeywords, loadRecents }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
                case .searchTapped(let text):
                    // 1) 상위로 검색 실행 위임, 2) 로컬 히스토리에 저장
                    return .merge(
                        .send(.delegate(.setKeyword(text))),
                        .run { [date] _ in
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            try await searchHistory.add(trimmed, date())
                        }
                    )
                case .deleteButtonTapped(let id):
                    if case .success(var items) = state.searchesResult {
                        items.removeAll(where: { $0.id == id })
                        state.searchesResult = .success(items)
                    }
                    return .run { _ in
                        try await searchHistory.delete(id)
                    }
                case .cancelLoading:
                    state.isSearchKeywordsLoading = false
                    state.isSearchesLoading = false
                    return .merge(
                        .cancel(id: CancelID.loadKeywords),
                        .cancel(id: CancelID.loadRecents)
                    )
                case .loadSearchKeyword:
                    state.isSearchKeywordsLoading = true
                    return .run {
                        send in
                        let result = await searchKeywordService.list(5)
                        await send(.loadSearchKeywordResponse(result))
                    }
                    .cancellable(id: CancelID.loadKeywords, cancelInFlight: true)
                case .loadRecents:
                    state.isSearchesLoading = true
                    return .run {
                        send in
                        do {
                            let items = try await searchHistory.fetchRecent(50)
                            await send(.loadRecentsResponse(.success(items)))
                        } catch {
                            let appError: AppError = .client(code: "RECENTS_LOAD_FAILED", message: error.localizedDescription)
                            await send(.loadRecentsResponse(.failure(appError)))
                        }
                    }
                    .cancellable(id: CancelID.loadRecents, cancelInFlight: true)
                case .onAppear:
                    return .merge(
                        .send(.loadRecents),
                        .send(.loadSearchKeyword)
                    )
                case .loadRecentsResponse(let result):
                    state.isSearchesLoading = false
                    state.searchesResult = result
                    return .none
                case .loadSearchKeywordResponse(let result):
                    state.searchKeywordsResult = result
                    state.isSearchKeywordsLoading = false
                    return .none
                case .delegate:
                    return .none
            }
        }
    }
}
