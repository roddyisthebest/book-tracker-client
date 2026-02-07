//
//  Collection.swift
//  BookTracker
//
//  Created by 배성연 on 2/7/26.
//

import Foundation

struct Collection: Equatable, Identifiable {
    let id: UUID
    let isDefault: Bool
    let title: String
    let description: String
}
