//
//  ReadingRecordService.swift
//  BookTracker
//
//  Created by 배성연 on 3/16/26.
//

import Foundation
import Supabase

struct MonthlyReadingReport: Equatable, Decodable {
    let month: MonthlyReadingReportMonth
    let comparison: MonthlyReadingReportComparison
}

struct MonthlyReadingReportMonth: Equatable, Decodable {
    let year: Int
    let month: Int
    let completedCount: Int
    let completedAverageScore: Double
    let purchaseCount: Int
    let purchaseAmount: Int
    let rentalCount: Int
    let unfinishedCount: Int
    let averageReadingDays: Double
    let paperCount: Int
    let ebookCount: Int
    let paperPercentage: Double
    let ebookPercentage: Double

    enum CodingKeys: String, CodingKey {
        case year
        case month
        case completedCount = "completed_count"
        case completedAverageScore = "completed_average_score"
        case purchaseCount = "purchase_count"
        case purchaseAmount = "purchase_amount"
        case rentalCount = "rental_count"
        case unfinishedCount = "unfinished_count"
        case averageReadingDays = "average_reading_days"
        case paperCount = "paper_count"
        case ebookCount = "ebook_count"
        case paperPercentage = "paper_percentage"
        case ebookPercentage = "ebook_percentage"
    }
}

struct MonthlyReadingReportComparison: Equatable, Decodable {
    let previousCompletedCount: Int
    let currentCompletedCount: Int
    let completedChangePercentage: Double

    let previousUnfinishedCount: Int
    let currentUnfinishedCount: Int
    let unfinishedChangePercentage: Double

    let previousPurchaseAmount: Int
    let currentPurchaseAmount: Int
    let purchaseAmountChangePercentage: Double

    let previousRentalCount: Int
    let currentRentalCount: Int
    let rentalCountChangePercentage: Double

    enum CodingKeys: String, CodingKey {
        case previousCompletedCount = "previous_completed_count"
        case currentCompletedCount = "current_completed_count"
        case completedChangePercentage = "completed_change_percentage"

        case previousUnfinishedCount = "previous_unfinished_count"
        case currentUnfinishedCount = "current_unfinished_count"
        case unfinishedChangePercentage = "unfinished_change_percentage"

        case previousPurchaseAmount = "previous_purchase_amount"
        case currentPurchaseAmount = "current_purchase_amount"
        case purchaseAmountChangePercentage = "purchase_amount_change_percentage"

        case previousRentalCount = "previous_rental_count"
        case currentRentalCount = "current_rental_count"
        case rentalCountChangePercentage = "rental_count_change_percentage"
    }
}

struct ReadingRecord: Equatable, Identifiable {
    let id: UUID
    let date: Date
    let userId: UUID
    let createdAt: Date
}

private enum ReadingRecordDateFormatter {
    static let day: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parseDate(_ value: String) -> Date? {
        day.date(from: value)
    }

    static func parseTimestamp(_ value: String) -> Date? {
        iso8601WithFractional.date(from: value) ?? iso8601.date(from: value)
    }

    static func dayString(from date: Date) -> String {
        day.string(from: date)
    }
}

private struct ReadingRecordsTableRow: Decodable {
    let id: UUID
    let date: String
    let userId: UUID
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

private struct ReadingRecordsInsertRow: Encodable {
    let date: String
}

private extension ReadingRecordsTableRow {
    func toDomain() throws -> ReadingRecord {
        guard let parsedDate = ReadingRecordDateFormatter.parseDate(date) else {
            throw AppError.storage(code: "INVALID_DATE", status: nil, message: "Invalid date: \(date)")
        }

        guard let parsedCreatedAt = ReadingRecordDateFormatter.parseTimestamp(createdAt) else {
            throw AppError.storage(code: "INVALID_CREATED_AT", status: nil, message: "Invalid created_at: \(createdAt)")
        }

        return ReadingRecord(
            id: id,
            date: parsedDate,
            userId: userId,
            createdAt: parsedCreatedAt
        )
    }
}

private struct MonthlyReadingReportPayload: Encodable {
    let pYear: Int
    let pMonth: Int

    enum CodingKeys: String, CodingKey {
        case pYear = "p_year"
        case pMonth = "p_month"
    }
}

struct ReadingRecordService {
    var create: (_ date: Date) async throws -> Result<ReadingRecord, AppError>
    var fetch: (_ id: UUID) async throws -> Result<ReadingRecord, AppError>
    var list: (_ limit: Int?, _ offset: Int?) async throws -> Result<[ReadingRecord], AppError>
    var hasRecordToday: () async throws -> Result<Bool, AppError>
    var recordForToday: () async throws -> Result<ReadingRecord?, AppError>
    var listRecentDays: (_ days: Int) async throws -> Result<[ReadingRecord], AppError>
    var listRecentDaysByDate: (_ days: Int) async throws -> Result<[Date: ReadingRecord?], AppError>
    var delete: (_ id: UUID) async throws -> Result<Void, AppError>
    var monthlyReport: (_ year: Int, _ month: Int) async -> Result<MonthlyReadingReport, AppError>
    var listByMonth: (_ year: Int, _ month: Int) async
        -> Result<[ReadingRecord], AppError>
    var listByMonthByDate: (_ year: Int, _ month: Int) async
        -> Result<[Date: ReadingRecord?], AppError>
}

extension ReadingRecordService {
    static func live(client: SupabaseClient) -> Self {
        let table = "reading_records"
        let monthlyReportRpc = "monthly_reading_report"

        return Self(
            create: { date in
                do {
                    let payload = ReadingRecordsInsertRow(
                        date: ReadingRecordDateFormatter.dayString(from: date)
                    )

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .insert(payload, returning: .representation)
                        .select()
                        .execute()

                    guard let row = response.value.first else {
                        return .failure(.storage(code: "EMPTY", status: nil, message: "Failed to insert reading record"))
                    }

                    return try .success(row.toDomain())
                } catch let error as AppError {
                    return .failure(error)
                } catch {
                    return .failure(.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            fetch: { id in
                do {
                    let response: PostgrestResponse<ReadingRecordsTableRow> = try await client
                        .from(table)
                        .select()
                        .eq("id", value: id.uuidString)
                        .single()
                        .execute()

                    return try .success(response.value.toDomain())
                } catch let error as AppError {
                    return .failure(error)
                } catch {
                    return .failure(.storage(code: "NOT_FOUND", status: 404, message: error.localizedDescription))
                }
            },
            list: { limit, offset in
                do {
                    var filter: PostgrestFilterBuilder = client
                        .from(table)
                        .select()

                    var transformed: PostgrestTransformBuilder = filter.order("date", ascending: false)
                    transformed = transformed.order("created_at", ascending: false)

                    if let limit = limit, let offset = offset {
                        transformed = transformed.range(from: offset, to: offset + limit - 1)
                    } else if let limit = limit {
                        transformed = transformed.limit(limit)
                    }

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await transformed.execute()
                    let records = try response.value.map { try $0.toDomain() }
                    return .success(records)
                } catch let error as AppError {
                    return .failure(error)
                } catch {
                    return .failure(.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            hasRecordToday: {
                do {
                    let todayString = ReadingRecordDateFormatter.dayString(from: Date())

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .select("id")
                        .eq("date", value: todayString)
                        .limit(1)
                        .execute()

                    return .success(!response.value.isEmpty)
                } catch {
                    return .failure(.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            recordForToday: {
                do {
                    let todayString = ReadingRecordDateFormatter.dayString(from: Date())

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .select()
                        .eq("date", value: todayString)
                        .limit(1)
                        .execute()

                    let record = try response.value.first?.toDomain()
                    return .success(record)
                } catch let error as AppError {
                    return .failure(error)
                } catch {
                    return .failure(.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            listRecentDays: { days in
                do {
                    let calendar = Calendar(identifier: .gregorian)
                    let end = Date()
                    let start = calendar.date(byAdding: .day, value: -max(days - 1, 0), to: end) ?? end

                    let formatter = DateFormatter()
                    formatter.calendar = calendar
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = .current
                    formatter.dateFormat = "yyyy-MM-dd"

                    let startStr = formatter.string(from: start)
                    let endStr = formatter.string(from: end)

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .select()
                        .gte("date", value: startStr)
                        .lte("date", value: endStr)
                        .order("date", ascending: true)
                        .execute()

                    let records = try response.value.map { try $0.toDomain() }
                    return .success(records)
                } catch {
                    return .failure(AppError.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            listRecentDaysByDate: { days in
                do {
                    let calendar = Calendar(identifier: .gregorian)
                    let end = Date()
                    let start = calendar.date(byAdding: .day, value: -max(days - 1, 0), to: end) ?? end

                    let formatter = DateFormatter()
                    formatter.calendar = calendar
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = .current
                    formatter.dateFormat = "yyyy-MM-dd"

                    let startStr = formatter.string(from: start)
                    let endStr = formatter.string(from: end)

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .select()
                        .gte("date", value: startStr)
                        .lte("date", value: endStr)
                        .order("date", ascending: true)
                        .order("created_at", ascending: false)
                        .execute()

                    let records = try response.value.map { try $0.toDomain() }

                    var byDate: [Date: ReadingRecord?] = [:]
                    let today = calendar.startOfDay(for: Date())
                    for offset in 0 ..< days {
                        if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                            let existing = records.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
                            byDate[date] = existing
                        }
                    }

                    return .success(byDate)
                } catch {
                    return .failure(AppError.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            delete: { id in
                do {
                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .delete(returning: .representation)
                        .eq("id", value: id.uuidString)
                        .select()
                        .execute()

                    guard !response.value.isEmpty else {
                        return .failure(.storage(
                            code: "NOT_DELETED",
                            status: nil,
                            message: "삭제된 row가 없습니다. RLS 또는 policy를 확인하세요."
                        ))
                    }

                    return .success(())
                } catch {
                    return .failure(.storage(code: "UNKNOWN", status: nil, message: error.localizedDescription))
                }
            },
            monthlyReport: { year, month in
                do {
                    let payload = MonthlyReadingReportPayload(
                        pYear: year,
                        pMonth: month
                    )

                    let response: PostgrestResponse<MonthlyReadingReport> = try await client
                        .rpc(monthlyReportRpc, params: payload)
                        .execute()

                    return .success(response.value)
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_MONTHLY_READING_REPORT_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            listByMonth: { year, month in
                do {
                    let calendar = Calendar(identifier: .gregorian)

                    guard let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                          let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)
                    else {
                        return .failure(
                            .storage(
                                code: "INVALID_YEAR_MONTH",
                                status: nil,
                                message: "Invalid year/month: \(year)-\(month)"
                            )
                        )
                    }

                    let formatter = DateFormatter()
                    formatter.calendar = calendar
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = .current
                    formatter.dateFormat = "yyyy-MM-dd"

                    let startStr = formatter.string(from: start)
                    let endStr = formatter.string(from: end)

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .select()
                        .gte("date", value: startStr)
                        .lte("date", value: endStr)
                        .order("date", ascending: true)
                        .order("created_at", ascending: false)
                        .execute()

                    let records = try response.value.map { try $0.toDomain() }
                    return .success(records)
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_LIST_BY_MONTH_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            listByMonthByDate: { year, month in
                do {
                    let calendar = Calendar(identifier: .gregorian)

                    guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                          let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart),
                          let lastDay = calendar.date(byAdding: .day, value: -1, to: nextMonthStart),
                          let dayCount = calendar.dateComponents([.day], from: monthStart, to: nextMonthStart).day
                    else {
                        return .failure(
                            .client(
                                code: "INVALID_YEAR_MONTH",
                                message: "Invalid year/month: \(year)-\(month)"
                            )
                        )
                    }

                    let formatter = DateFormatter()
                    formatter.calendar = calendar
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = .current
                    formatter.dateFormat = "yyyy-MM-dd"

                    let startStr = formatter.string(from: monthStart)
                    let endStr = formatter.string(from: lastDay)

                    let response: PostgrestResponse<[ReadingRecordsTableRow]> = try await client
                        .from(table)
                        .select()
                        .gte("date", value: startStr)
                        .lte("date", value: endStr)
                        .order("date", ascending: true)
                        .order("created_at", ascending: false)
                        .execute()

                    let records = try response.value.map { try $0.toDomain() }

                    var byDate: [Date: ReadingRecord?] = [:]
                    let startOfMonth = calendar.startOfDay(for: monthStart)

                    for offset in 0 ..< dayCount {
                        if let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth) {
                            let existing = records.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
                            byDate[date] = existing
                        }
                    }

                    return .success(byDate)
                } catch let error as AppError {
                    return .failure(error)
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
        )
    }
}
