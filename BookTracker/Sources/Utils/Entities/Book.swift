//
//  Book.swift
//  BookTracker
//
//  Created by 배성연 on 2/8/26.
//

import Foundation

enum BookStatus: Equatable, CaseIterable, Identifiable, Hashable {
    case reading
    case want
    case done
    case dropped

    var id: Self { self }

    var title: String {
        switch self {
        case .reading: return "읽는 중"
        case .want: return "읽고 싶은"
        case .done: return "완독"
        case .dropped: return "읽다 만"
        }
    }
}

enum BookType: Equatable, CaseIterable, Identifiable, Hashable {
    case ebook
    case paper

    var id: Self { self }

    var title: String {
        switch self {
        case .ebook: return "전자책"
        case .paper: return "종이책"
        }
    }
}

struct Book: Equatable {
    let id: UUID
    let title: String
    let author: String
    let publisher: String
    let imageUrl: String?
    let isbn: String
    let status: BookStatus
    let type: BookType
}
