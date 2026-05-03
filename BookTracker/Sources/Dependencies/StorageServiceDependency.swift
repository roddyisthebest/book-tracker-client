//
//  StorageServiceDependency.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture

private enum StorageServiceKey: DependencyKey {
    static let liveValue: StorageService = .live(client: SupabaseFactory.make())

    static let testValue: StorageService = .init(
        uploadBookCover: { _ in .failure(.unknown(message: "unimplemented")) }
    )

    static let previewValue: StorageService = liveValue
}

extension DependencyValues {
    var storageService: StorageService {
        get { self[StorageServiceKey.self] }
        set { self[StorageServiceKey.self] = newValue }
    }
}
