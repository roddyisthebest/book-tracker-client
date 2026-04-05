//
//  ReceiptServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/28/26.
//

import ComposableArchitecture

private enum ReceiptServiceKey: DependencyKey {
    static let liveValue: ReceiptService = .live(client: SupabaseFactory.make())
}

extension DependencyValues {
    var receiptService: ReceiptService {
        get { self[ReceiptServiceKey.self] }
        set { self[ReceiptServiceKey.self] = newValue }
    }
}
