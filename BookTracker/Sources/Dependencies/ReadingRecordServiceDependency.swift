//
//  ReadingRecordServiceDependency.swift
//  BookTracker
//
//  Created by AI on 3/17/26.
//

import ComposableArchitecture

private enum ReadingRecordServiceKey: DependencyKey {
    static let liveValue: ReadingRecordService = .live(client: SupabaseFactory.make())

//    static let testValue: ReadingRecordService = .init(
//        create: { _ in throw Unimplemented("ReadingRecordService.create is unimplemented") },
//        fetch: { _ in throw Unimplemented("ReadingRecordService.fetch is unimplemented") },
//        list: { _, _ in throw Unimplemented("ReadingRecordService.list is unimplemented") },
//        hasRecordToday: { throw Unimplemented("ReadingRecordService.hasRecordToday is unimplemented") },
//        recordForToday: { throw Unimplemented("ReadingRecordService.recordForToday is unimplemented") },
//        listRecentDays: { _ in throw Unimplemented("ReadingRecordService.delete is unimplemented") },
//        listRecentDaysByDate: { _ in throw Unimplemented("ReadingRecordService.listRecentDays is unimplemented") },
//        delete: {
//            _ in throw Unimplemented("ReadingRecordService.listRecentDaysByDate is unimplemented"),
//        }
//    )

    static let previewValue: ReadingRecordService = liveValue
}

extension DependencyValues {
    var readingRecordService: ReadingRecordService {
        get { self[ReadingRecordServiceKey.self] }
        set { self[ReadingRecordServiceKey.self] = newValue }
    }
}
