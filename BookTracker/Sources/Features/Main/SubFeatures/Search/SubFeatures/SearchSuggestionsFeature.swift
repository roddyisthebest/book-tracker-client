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
    @Dependency(\.date) var date

    @ObservableState
    struct State: Equatable {
        var searches: [Search] = []
        var books: [ExternalBook] = [
            ExternalBook(id: "ad2231", title: "괜찮아 괜찮43괜찮아 괜찮asdddsasd asdasdfdfadasdfsadfdsafdsfdsf"),
            ExternalBook(id: "ad2232", title: "마이노2"),
            ExternalBook(id: "ad2233", title: "괜찮아 괜찮43괜찮아 괜찮43 괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43괜찮아 괜찮43"),
        ]
    }

    enum Action: Equatable {
        case searchTapped(text: String)
        case deleteButtonTapped(id: String)
        case onAppear
        case recentLoaded([Search])

        case delegate(Delegate)
        enum Delegate: Equatable {
            case setKeyword(String)
        }
    }

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
                    state.searches.removeAll(where: { $0.id == id })
                    return .run { _ in
                        try await searchHistory.delete(id)
                    }
                case .onAppear:
                    return .run { send in
                        let items = try await searchHistory.fetchRecent(50)
                        await send(.recentLoaded(items))
                    }
                case .recentLoaded(let items):
                    state.searches = items
                    return .none
                case .delegate:
                    return .none
            }
        }
    }
}
