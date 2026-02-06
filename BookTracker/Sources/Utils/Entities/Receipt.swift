//
//  Receipt.swift
//  BookTracker
//
//  Created by 배성연 on 2/5/26.
//

import Foundation

enum ReceiptType: Equatable, Hashable {
    case purchase
    case rental
}

struct Receipt: Equatable, Identifiable {
    let id: UUID
    let type: ReceiptType
    let title: String
}
