//
//  Search.swift
//  BookTracker
//
//  Created by 배성연 on 2/17/26.
//

import Foundation

struct Search: Equatable, Identifiable {
    let id: UUID
    let text: String

    let createdAt: Date
}
