//
//  ReadingRecordService.swift
//  BookTracker
//
//  Created by 배성연 on 3/16/26.
//

import Foundation
import Supabase

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

struct ReadingRecordService {
    var create: (_ date: Date) async throws -> Result<ReadingRecord, AppError>
    var fetch: (_ id: UUID) async throws -> Result<ReadingRecord, AppError>
    var list: (_ limit: Int?, _ offset: Int?) async throws -> Result<[ReadingRecord], AppError>
    var hasRecordToday: () async throws -> Result<Bool, AppError>
    var recordForToday: () async throws -> Result<ReadingRecord?, AppError>
    var listRecentDays: (_ days: Int) async throws -> Result<[ReadingRecord], AppError>
    var listRecentDaysByDate: (_ days: Int) async throws -> Result<[Date: ReadingRecord?], AppError>
    var delete: (_ id: UUID) async throws -> Result<Void, AppError>
}

extension ReadingRecordService {
    static func live(client: SupabaseClient) -> Self {
        let table = "reading_records"

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
            }
        )
    }
}
