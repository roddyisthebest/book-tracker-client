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

extension Book {
    static func make(
        id: UUID = UUID(),
        title: String,
        author: String,
        publisher: String = "",
        imageUrl: String? = nil,
        isbn: String = "",
        status: BookStatus = .reading,
        type: BookType = .paper
    ) -> Book {
        Book(
            id: id,
            title: title,
            author: author,
            publisher: publisher,
            imageUrl: imageUrl,
            isbn: isbn,
            status: status,
            type: type
        )
    }

    static func make() -> Book {
        Book.make(title: "ddasds", author: "asdasdsssasd")
    }
}
