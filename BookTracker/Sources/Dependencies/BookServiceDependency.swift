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
        create: { _ in .failure(.unknown(message: "unimplemented")) },
        fetch: { _ in .failure(.unknown(message: "unimplemented")) },
        list: { _, _, _, _ in .failure(.unknown(message: "unimplemented")) },
        update: { _, _ in .failure(.unknown(message: "unimplemented")) },
        delete: { _ in .failure(.unknown(message: "unimplemented")) },
        isAlreadyRegistered: { _ in .failure(.unknown(message: "unimplemented")) },
        statusCounts: { .failure(.unknown(message: "unimplemented")) },
        calendarByMonth: { _, _, _, _ in .failure(.unknown(message: "unimplemented")) }
    )

    static let previewValue: BookService = liveValue
}

extension DependencyValues {
    var bookService: BookService {
        get { self[BookServiceKey.self] }
        set { self[BookServiceKey.self] = newValue }
    }
}
