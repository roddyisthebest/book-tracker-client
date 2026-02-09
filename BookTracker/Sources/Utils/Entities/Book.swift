//
//  Book.swift
//  BookTracker
//
//  Created by 배성연 on 2/8/26.
//

import Foundation

struct Book: Equatable {
    let id: UUID
    let title: String
    let author: String
    let publisher: String
    let imageUrl: String?
    let isbn: String
}
