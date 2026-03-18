//
//  BookServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/11/26.
//

import ComposableArchitecture
import Foundation

private enum BookServiceKey: DependencyKey {
    static let liveValue: BookService = .live(client: SupabaseFactory.make())

    static let testValue: BookService = .init(
        create: { _ in throw BookServiceError.notFound },
        fetch: { _ in throw BookServiceError.notFound },
        list: { _, _, _ in throw BookServiceError.notFound },
        update: { _, _ in throw BookServiceError.notFound },
        delete: { _ in throw BookServiceError.notFound },
        isAlreadyRegistered: { _ in throw BookServiceError.notFound },
        statusCounts: { throw BookServiceError.notFound },
    )

    static let previewValue: BookService = liveValue
}

extension DependencyValues {
    var bookService: BookService {
        get { self[BookServiceKey.self] }
        set { self[BookServiceKey.self] = newValue }
    }
}
