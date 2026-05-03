//
//  LocalReceiptServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/25/26.
//

import ComposableArchitecture
import Foundation

private enum LocalReceiptServiceKey: DependencyKey {
    static let liveValue: LocalReceiptService = .live()

    static let testValue: LocalReceiptService = .init(
        fetchAll: { _ in .success([]) },
        fetchBooks: { _, _ in .success([]) },
        save: { _, _, type in .success(type) },
        saveReceiptBook: { _, book in .success(book) },
        remove: { _, id, _ in .success(id) },
        removeSpecificTypes: { _, _ in .success(true) },
        removeAllTypes: { _, _ in .success(()) },
        clearAll: { _ in .success(()) },
        contains: { _, _, _ in .success(false) },
        registeredTypes: { _, _ in .success([]) },
        isRegisteredInPurchase: { _, _ in .success(false) },
        isRegisteredInRental: { _, _ in .success(false) },
        count: { _, _ in .success(0) },
        counts: { _ in .success([.purchase: 0, .rental: 0]) }
    )
}

extension DependencyValues {
    var localReceiptService: LocalReceiptService {
        get { self[LocalReceiptServiceKey.self] }
        set { self[LocalReceiptServiceKey.self] = newValue }
    }
}
