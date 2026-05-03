@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ReadingCalendarFeatureTests {
    @Test func onAppear_loadsData() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: ReadingCalendarFeature.State(date: fixedDate),
            reducer: { ReadingCalendarFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)

        let records: [Date: ReadingRecord?] = [
            Date(timeIntervalSince1970: 1_700_000_000): TestFixtures.readingRecord,
        ]

        store.dependencies.readingRecordService.listByMonthByDate = { _, _ in .success(records) }

        await store.send(.onAppear)
        await store.receive(\.loadData) {
            $0.isLoading = true
            $0.readingRecords = nil
        }

        await store.receive(\.loadDataResponse) {
            $0.isLoading = false
            $0.readingRecords = records
        }
    }

    @Test func loadData_failure_setsError() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: ReadingCalendarFeature.State(date: fixedDate),
            reducer: { ReadingCalendarFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.readingRecordService.listByMonthByDate = { _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadData) {
            $0.isLoading = true
            $0.readingRecords = nil
        }

        await store.receive(\.loadDataResponse) {
            $0.isLoading = false
            $0.isError = true
        }
    }

    @Test func saveSuccess_showsAlert() async {
        let store = TestStore(
            initialState: ReadingCalendarFeature.State(),
            reducer: { ReadingCalendarFeature() }
        )
        store.exhaustivity = .off

        await store.send(.saveSuccess) {
            $0.alert = .saveSuccess()
        }
    }

    @Test func saveFailed_showsAlert() async {
        let store = TestStore(
            initialState: ReadingCalendarFeature.State(),
            reducer: { ReadingCalendarFeature() }
        )
        store.exhaustivity = .off

        await store.send(.saveFailed) {
            $0.alert = .saveFailed()
        }
    }
}
