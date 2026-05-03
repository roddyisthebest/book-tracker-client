//
//  ReceiptServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/28/26.
//

import ComposableArchitecture

private enum ReceiptServiceKey: DependencyKey {
    static let liveValue: ReceiptService = .live(client: SupabaseFactory.make())

    static let testValue: ReceiptService = .init(
        createReceiptWithBooks: { _, _, _, _, _, _ in .failure(.unknown(message: "unimplemented")) },
        loadReceipts: { _, _, _ in .failure(.unknown(message: "unimplemented")) },
        loadReceiptDetail: { _ in .failure(.unknown(message: "unimplemented")) },
        deleteReceipt: { _ in .failure(.unknown(message: "unimplemented")) }
    )
}

extension DependencyValues {
    var receiptService: ReceiptService {
        get { self[ReceiptServiceKey.self] }
        set { self[ReceiptServiceKey.self] = newValue }
    }
}
