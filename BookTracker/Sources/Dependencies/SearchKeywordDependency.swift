//
//  SearchKeywordDependency.swift
//  BookTracker
//
//  Created by 배성연 on 4/7/26.
//

import ComposableArchitecture

private enum SearchKeywordServiceKey: DependencyKey {
    static let liveValue: SearchKeywordService = .live(client: SupabaseFactory.make())
}

extension DependencyValues {
    var searchKeywordService: SearchKeywordService {
        get { self[SearchKeywordServiceKey.self] }
        set { self[SearchKeywordServiceKey.self] = newValue }
    }
}
