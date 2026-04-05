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
    let userId: UUID
    let externalBookId: String?

    let title: String
    let author: String
    let publisher: String
    let pageCount: Int?
    let pageCountEditable: Bool

    let imageUrl: String?
    let isbn: String

    let status: BookStatus
    let type: BookType

    // status-driven

    // .reading
    let startedAt: Date?
    let readCount: Int?
    let memo: String?

    // .want
//    let memo: String?

    // .done
//    let startedAt: Date?
    let endedAt: Date?
    let score: Double?
    let review: String?

    // .dropped
    let droppedReason: String?
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
            userId: UUID(),
            externalBookId: nil,
            title: title,
            author: author,
            publisher: publisher,
            pageCount: nil,
            pageCountEditable: false,
            imageUrl: imageUrl,
            isbn: isbn,
            status: status,
            type: type,
            startedAt: nil,
            readCount: nil,
            memo: nil,
            endedAt: nil,
            score: nil,
            review: nil,
            droppedReason: nil
        )
    }

    static func make() -> Book {
        Book.make(title: "ddasds", author: "asdasdsssasd")
    }
}

extension BookStatus {
    init(dbValue: String?) {
        switch dbValue {
        case "reading": self = .reading
        case "want": self = .want
        case "done": self = .done
        case "dropped": self = .dropped
        default: self = .want
        }
    }
}

extension BookType {
    init(dbValue: String?) {
        switch dbValue {
        case "ebook": self = .ebook
        case "paper": self = .paper
        default: self = .paper
        }
    }
}
