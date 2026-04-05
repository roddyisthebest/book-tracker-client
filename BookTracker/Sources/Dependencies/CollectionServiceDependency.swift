//
//  CollectionServiceDependency.swift
//  BookTracker
//
//  Created by Assistant on 3/20/26.
//

import ComposableArchitecture
import Foundation

private enum CollectionServiceKey: DependencyKey {
    static let liveValue: CollectionService = .live(client: SupabaseFactory.make())

    static let testValue: CollectionService = .init(
        create: { _ in .failure(AppError.unknown(message: "not implemented")) },
        addBooks: { _, _ in .failure(AppError.unknown(message: "not implemented")) },
        createWithBooks: { _, _ in .failure(AppError.unknown(message: "not implemented")) },
        update: { _, _ in .failure(AppError.unknown(message: "not implemented")) },
        list: { .failure(AppError.unknown(message: "not implemented")) },
        listSummaries: { _, _ in .failure(AppError.unknown(message: "not implemented")) },
        listBooks: { _, _, _ in .failure(AppError.unknown(message: "not implemented")) },
        syncBooks: { _, _ in .failure(AppError.unknown(message: "not implemented")) },
        items: { _ in .failure(AppError.unknown(message: "not implemented")) },
        delete: { _ in .failure(AppError.unknown(message: "not implemented")) },
        deleteItem: { _ in .failure(AppError.unknown(message: "not implemented")) }
    )

    static let previewValue: CollectionService = liveValue
}

extension DependencyValues {
    var collectionService: CollectionService {
        get { self[CollectionServiceKey.self] }
        set { self[CollectionServiceKey.self] = newValue }
    }
}
