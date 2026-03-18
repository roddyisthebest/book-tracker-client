//
//  SearchHistoryDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/7/26.
//
import ComposableArchitecture

private enum SearchHistoryClientKey: DependencyKey {
    static let liveValue: SearchHistoryClient = .live()
    static let testValue: SearchHistoryClient = .init(
        fetchRecent: { _ in [] },
        add: { _, _ in },
        delete: { _ in },
        clearAll: {}
    )
    static let previewValue: SearchHistoryClient = liveValue
}

extension DependencyValues {
    var searchHistory: SearchHistoryClient {
        get { self[SearchHistoryClientKey.self] }
        set { self[SearchHistoryClientKey.self] = newValue }
    }
}
