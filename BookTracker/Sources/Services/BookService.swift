//
//  BookService.swift
//  BookTracker
//
//  Created by 배성연 on 3/10/26.
//

import Foundation
import Supabase

// MARK: - Service Errors

enum BookServiceError: Error, LocalizedError {
    case notFound
    case emptyResponse
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .notFound: return "Book not found"
        case .emptyResponse: return "Empty response from server"
        case .encodingFailed: return "Failed to encode payload"
        }
    }
}

// MARK: - Database Row Models

// These mirror the database schema (snake_case) and are used for decoding/encoding with Supabase.
private struct BooksTableRow: Codable {
    let id: UUID
    let userId: UUID?
    let externalBookId: String?
    let title: String?
    let author: String?
    let publisher: String?
    let pageCount: Int?
    let imageUrl: String?
    let status: String?
    let type: String?
    let memo: String?
    let droppedReason: String?
    let createdAt: Date?
    let isbn: String?
    let startedAt: Date?
    let endedAt: Date?
    let readCount: Int?
    let score: Double?
    let review: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case externalBookId = "external_book_id"
        case title
        case author
        case publisher
        case pageCount = "page_count"
        case imageUrl = "image_url"
        case status
        case type
        case memo
        case droppedReason = "dropped_reason"
        case createdAt = "created_at"
        case isbn
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case readCount = "read_count"
        case score
        case review
    }
}

private struct BooksUpsertRow: Encodable {
    var id: UUID?
    var externalBookId: String?
    var title: String?
    var author: String?
    var publisher: String?
    var pageCount: Int?
    var imageUrl: String?
    var status: String?
    var type: String?
    var memo: String?
    var droppedReason: String?
    var isbn: String?
    var startedAt: Date?
    var endedAt: Date?
    var readCount: Int?
    var score: Double?
    var review: String?

    enum CodingKeys: String, CodingKey {
        case id
        case externalBookId = "external_book_id"
        case title
        case author
        case publisher
        case pageCount = "page_count"
        case imageUrl = "image_url"
        case status
        case type
        case memo
        case droppedReason = "dropped_reason"
        case isbn
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case readCount = "read_count"
        case score
        case review
    }
}

private struct StatusCountRow: Decodable {
    let status: String?
    let count: Int?
}

// MARK: - Mapping Helpers

private extension BooksTableRow {
    func toDomain() -> Book {
        Book(
            id: id,
            userId: userId ?? UUID(),
            externalBookId: externalBookId,
            title: title ?? "",
            author: author ?? "",
            publisher: publisher ?? "",
            pageCount: pageCount,
            pageCountEditable: externalBookId?.hasPrefix("custom_") ?? false,
            imageUrl: imageUrl,
            isbn: isbn ?? "",
            status: BookService.mapStatusFromDB(status),
            type: BookService.mapTypeFromDB(type),
            startedAt: startedAt,
            readCount: readCount,
            memo: memo,
            endedAt: endedAt,
            score: score,
            review: review,
            droppedReason: droppedReason
        )
    }
}

private extension BooksUpsertRow {
    init(from book: Book) {
        self.id = book.id
        self.externalBookId = book.externalBookId
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.pageCount = book.pageCount
        self.imageUrl = book.imageUrl
        self.status = BookService.mapStatusToDB(book.status)
        self.type = BookService.mapTypeToDB(book.type)
        self.memo = book.memo
        self.droppedReason = book.droppedReason
        self.isbn = book.isbn
        self.startedAt = book.startedAt
        self.endedAt = book.endedAt
        self.readCount = book.readCount
        self.score = book.score
        self.review = book.review
    }
}

// A patch model for partial updates
struct BookPatch {
    var externalBookId: String? = nil
    var title: String? = nil
    var author: String? = nil
    var publisher: String? = nil
    var pageCount: Int? = nil
    var imageUrl: String? = nil
    var status: BookStatus? = nil
    var type: BookType? = nil
    var memo: String? = nil
    var droppedReason: String? = nil
    var isbn: String? = nil
    var startedAt: Date? = nil
    var endedAt: Date? = nil
    var readCount: Int? = nil
    var score: Double? = nil
    var review: String? = nil
}

struct BookCalendarSummary: Equatable, Decodable, Hashable {
    let id: UUID
    let title: String?
    let imageUrl: String?
    let endedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageUrl = "image_url"
        case endedAt = "ended_at"
    }
}

struct BookCalendarDay: Equatable, Hashable {
    let books: [BookCalendarSummary]
    let totalCount: Int

    static let empty = BookCalendarDay(books: [], totalCount: 0)
}

private struct BookCalendarDayRow: Decodable {
    let endedDate: String
    let totalCount: Int
    let books: [BookCalendarSummary]

    enum CodingKeys: String, CodingKey {
        case endedDate = "ended_date"
        case totalCount = "total_count"
        case books
    }
}

private struct BooksCalendarByMonthPayload: Encodable {
    let pYear: Int
    let pMonth: Int
    let pStatus: String?
    let pType: String?

    enum CodingKeys: String, CodingKey {
        case pYear = "p_year"
        case pMonth = "p_month"
        case pStatus = "p_status"
        case pType = "p_type"
    }
}

private extension BooksUpsertRow {
    init(from patch: BookPatch) {
        self.id = nil
        self.externalBookId = patch.externalBookId
        self.title = patch.title
        self.author = patch.author
        self.publisher = patch.publisher
        self.pageCount = patch.pageCount
        self.imageUrl = patch.imageUrl
        self.status = patch.status.map { BookService.mapStatusToDB($0) }
        self.type = patch.type.map { BookService.mapTypeToDB($0) }
        self.memo = patch.memo
        self.droppedReason = patch.droppedReason
        self.isbn = patch.isbn
        self.startedAt = patch.startedAt
        self.endedAt = patch.endedAt
        self.readCount = patch.readCount
        self.score = patch.score
        self.review = patch.review
    }
}

// MARK: - BookService

struct BookService {
    var create: (_ book: Book) async throws -> Result<Book, AppError>
    var fetch: (_ id: UUID) async throws -> Result<Book, AppError>
    var list: (
        _ status: BookStatus?,
        _ sort: BookSortOption,
        _ limit: Int?,
        _ offset: Int?
    ) async throws -> Result<[Book], AppError>
    var update: (_ id: UUID, _ patch: BookPatch) async throws -> Result<Book, AppError>
    var delete: (_ id: UUID) async -> Result<UUID, AppError>
    var isAlreadyRegistered: (_ externalBookId: String) async throws -> Result<Bool, AppError>
    var statusCounts: () async throws -> Result<[BookStatus: Int], AppError>
    var calendarByMonth: (
        _ year: Int,
        _ month: Int,
        _ status: BookStatus?,
        _ type: BookType?
    ) async -> Result<[Date: BookCalendarDay], AppError>
}

extension BookService {
    static func live(client: SupabaseClient) -> Self {
        let table = "books"
        let byMonthRpcName = "books_calendar_by_month"

        return Self(
            create: { book in
                let payload = BooksUpsertRow(from: book)
                let response: PostgrestResponse<[BooksTableRow]> = try await client
                    .from(table)
                    .insert(payload, returning: .representation)
                    .select()
                    .execute()
                guard let row = response.value.first else { return .failure(AppError.storage(code: "", status: nil, message: "Failed to insert book")) }
                let new = row.toDomain()
                return .success(new)
            },
            fetch: { id in
                let response: PostgrestResponse<BooksTableRow> = try await client
                    .from(table)
                    .select()
                    .eq("id", value: id.uuidString)
                    .single()
                    .execute()
                let book = response.value.toDomain()
                return .success(book)
            },
            list: { status, sort, limit, offset in
                var filter: PostgrestFilterBuilder = client
                    .from(table)
                    .select()

                if let status = status {
                    filter = filter.eq("status", value: Self.mapStatusToDB(status))
                }

                let transformedBase: PostgrestTransformBuilder

                switch sort {
                case .oldest:
                    transformedBase = filter.order("created_at", ascending: true)

                case .newest:
                    transformedBase = filter.order("created_at", ascending: false)

                case .titleAsc:
                    transformedBase = filter
                        .order("title", ascending: true)
                        .order("created_at", ascending: false)

                case .titleDesc:
                    transformedBase = filter
                        .order("title", ascending: false)
                        .order("created_at", ascending: false)
                }

                var transformed = transformedBase

                if let limit, let offset {
                    transformed = transformed.range(from: offset, to: offset + limit - 1)
                } else if let limit {
                    transformed = transformed.limit(limit)
                } else if let offset {
                    transformed = transformed.range(from: offset, to: offset + 50 - 1)
                }

                let response: PostgrestResponse<[BooksTableRow]> = try await transformed.execute()
                let books = response.value.map { $0.toDomain() }

                return .success(books)
            },
            update: { id, patch in
                do {
                    let payload = BooksUpsertRow(from: patch)

                    let response: PostgrestResponse<[BooksTableRow]> = try await client
                        .from(table)
                        .update(payload, returning: .representation)
                        .eq("id", value: id.uuidString)
                        .select()
                        .execute()

                    guard let row = response.value.first else {
                        return .failure(
                            .storage(
                                code: "NOT_UPDATED",
                                status: 404,
                                message: "Book was not updated. Check RLS/select/update policies or id mismatch."
                            )
                        )
                    }

                    return .success(row.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "UNKNOWN",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            delete: { id in
                do {
                    let response: PostgrestResponse<[BooksTableRow]> = try await client
                        .from(table)
                        .delete(returning: .representation)
                        .eq("id", value: id.uuidString)
                        .select()
                        .execute()

                    guard !response.value.isEmpty else {
                        return .failure(
                            .storage(
                                code: "NOT_DELETED",
                                status: 404,
                                message: "Book was not deleted. Check RLS/select/delete policies or id mismatch."
                            )
                        )
                    }

                    return .success(id)
                } catch {
                    return .failure(
                        .storage(
                            code: "UNKNOWN",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            isAlreadyRegistered: { externalBookId in
                do {
                    let response: PostgrestResponse<[BooksTableRow]> = try await client
                        .from(table)
                        .select("id")
                        .eq("external_book_id", value: externalBookId)
                        .limit(1)
                        .execute()
                    let exists = !response.value.isEmpty
                    return .success(exists)
                } catch {
                    return .failure(AppError.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            statusCounts: {
                do {
                    let response: PostgrestResponse<[StatusCountRow]> = try await client
                        .rpc("books_status_counts")
                        .execute()

                    var counts: [BookStatus: Int] = [
                        .reading: 0,
                        .want: 0,
                        .done: 0,
                        .dropped: 0
                    ]

                    for row in response.value {
                        guard let raw = row.status else { continue }
                        let status = Self.mapStatusFromDB(raw)
                        counts[status] = row.count ?? 0
                    }

                    return .success(counts)
                } catch {
                    return .failure(AppError.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            calendarByMonth: { year, month, status, type in
                do {
                    let payload = BooksCalendarByMonthPayload(
                        pYear: year,
                        pMonth: month,
                        pStatus: status.map { Self.mapStatusToDB($0) },
                        pType: type.map { Self.mapTypeToDB($0) }
                    )

                    let response: PostgrestResponse<[BookCalendarDayRow]> = try await client
                        .rpc(byMonthRpcName, params: payload)
                        .execute()

                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")

                    let calendar = Calendar(identifier: .gregorian)

                    // Parse server response into [Date: BookCalendarDay]
                    var grouped: [Date: BookCalendarDay] = [:]
                    for row in response.value {
                        guard let date = dateFormatter.date(from: row.endedDate) else { continue }
                        let key = calendar.startOfDay(for: date)
                        grouped[key] = BookCalendarDay(books: row.books, totalCount: row.totalCount)
                    }

                    // Fill all days of the month
                    guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                          let range = calendar.range(of: .day, in: .month, for: start)
                    else {
                        return .success(grouped)
                    }

                    let startOfMonth = calendar.startOfDay(for: start)
                    var filled: [Date: BookCalendarDay] = [:]
                    for day in range {
                        if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                            let key = calendar.startOfDay(for: date)
                            filled[key] = grouped[key] ?? .empty
                        }
                    }

                    return .success(filled)
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_BOOKS_CALENDAR_BY_MONTH_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        )
    }
}

// MARK: - Enum Mapping

extension BookService {
    static func mapStatusFromDB(_ status: String?) -> BookStatus {
        switch status?.lowercased() {
        case "reading": return .reading
        case "want": return .want
        case "done": return .done
        case "dropped": return .dropped
        default: return .want
        }
    }

    static func mapTypeFromDB(_ type: String?) -> BookType {
        switch type?.lowercased() {
        case "ebook": return .ebook
        case "paper": return .paper
        default: return .paper
        }
    }

    static func mapStatusToDB(_ status: BookStatus) -> String {
        switch status {
        case .reading: return "reading"
        case .want: return "want"
        case .done: return "done"
        case .dropped: return "dropped"
        }
    }

    static func mapTypeToDB(_ type: BookType) -> String {
        switch type {
        case .ebook: return "ebook"
        case .paper: return "paper"
        }
    }
}

