//
//  ExternalBooksServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/6/26.
//

import ComposableArchitecture

// Register ExternalBooksService as a TCA dependency, similar to AuthService.
private enum ExternalBookServiceKey: DependencyKey {
    static let liveValue: ExternalBookService = .live()

    static let testValue: ExternalBookService = .init(
        search: { _, _, _ in throw Unimplemented("ExternalBooksService.search is unimplemented") },
        detail: { _ in throw Unimplemented("ExternalBooksService.detail is unimplemented") }
    )
}

extension DependencyValues {
    var externalBookService: ExternalBookService {
        get { self[ExternalBookServiceKey.self] }
        set { self[ExternalBookServiceKey.self] = newValue }
    }
}
