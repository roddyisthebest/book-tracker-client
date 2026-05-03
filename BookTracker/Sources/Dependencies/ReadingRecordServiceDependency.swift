//
//  ReadingRecordServiceDependency.swift
//  BookTracker
//
//  Created by AI on 3/17/26.
//

import ComposableArchitecture

private enum ReadingRecordServiceKey: DependencyKey {
    static let liveValue: ReadingRecordService = .live(client: SupabaseFactory.make())

    static let testValue: ReadingRecordService = .init(
        create: { _ in .failure(.unknown(message: "unimplemented")) },
        fetch: { _ in .failure(.unknown(message: "unimplemented")) },
        list: { _, _ in .failure(.unknown(message: "unimplemented")) },
        hasRecordToday: { .failure(.unknown(message: "unimplemented")) },
        recordForToday: { .failure(.unknown(message: "unimplemented")) },
        listRecentDays: { _ in .failure(.unknown(message: "unimplemented")) },
        listRecentDaysByDate: { _ in .failure(.unknown(message: "unimplemented")) },
        delete: { _ in .failure(.unknown(message: "unimplemented")) },
        monthlyReport: { _, _ in .failure(.unknown(message: "unimplemented")) },
        listByMonth: { _, _ in .failure(.unknown(message: "unimplemented")) },
        listByMonthByDate: { _, _ in .failure(.unknown(message: "unimplemented")) }
    )

    static let previewValue: ReadingRecordService = liveValue
}

extension DependencyValues {
    var readingRecordService: ReadingRecordService {
        get { self[ReadingRecordServiceKey.self] }
        set { self[ReadingRecordServiceKey.self] = newValue }
    }
}
