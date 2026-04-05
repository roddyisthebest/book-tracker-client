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
}

extension DependencyValues {
    var localReceiptService: LocalReceiptService {
        get { self[LocalReceiptServiceKey.self] }
        set { self[LocalReceiptServiceKey.self] = newValue }
    }
}
