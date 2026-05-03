//
//  LocalCustomBookServiceDependency.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture
import Foundation

private enum LocalCustomBookServiceKey: DependencyKey {
    static let liveValue: LocalCustomBookService = .live()

    static let testValue: LocalCustomBookService = .init(
        fetchAll: { _ in .success([]) },
        save: { book, _ in .success(book) },
        remove: { id, _ in .success(id) },
        clearAll: { _ in .success(()) }
    )
}

extension DependencyValues {
    var localCustomBookService: LocalCustomBookService {
        get { self[LocalCustomBookServiceKey.self] }
        set { self[LocalCustomBookServiceKey.self] = newValue }
    }
}
