@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct DoneBooksCalendarFeatureTests {
    @Test func onAppear_loadsData() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: DoneBooksCalendarFeature.State(date: fixedDate),
            reducer: { DoneBooksCalendarFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)

        let summary = BookCalendarSummary(
            id: TestFixtures.bookId,
            title: "Done Book",
            imageUrl: "https://example.com/cover.jpg",
            endedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data: [Date: [BookCalendarSummary]] = [
            Date(timeIntervalSince1970: 1_700_000_000): [summary],
        ]

        store.dependencies.bookService.calendarByMonth = { _, _, _, _ in .success(data) }

        await store.send(.onAppear)
        await store.receive(\.loadData) {
            $0.isLoading = true
            $0.thumbnailsByDate = nil
        }

        await store.receive(\.loadDataResponse) {
            $0.isLoading = false
            $0.thumbnailsByDate = data
        }
    }

    @Test func loadData_failure_setsError() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: DoneBooksCalendarFeature.State(date: fixedDate),
            reducer: { DoneBooksCalendarFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.bookService.calendarByMonth = { _, _, _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadData) {
            $0.isLoading = true
            $0.thumbnailsByDate = nil
        }

        await store.receive(\.loadDataResponse) {
            $0.isLoading = false
            $0.isError = true
        }
    }

    @Test func saveSuccess_showsAlert() async {
        let store = TestStore(
            initialState: DoneBooksCalendarFeature.State(),
            reducer: { DoneBooksCalendarFeature() }
        )
        store.exhaustivity = .off

        await store.send(.saveSuccess) {
            $0.alert = .saveSuccess()
        }
    }

    @Test func saveFailed_showsAlert() async {
        let store = TestStore(
            initialState: DoneBooksCalendarFeature.State(),
            reducer: { DoneBooksCalendarFeature() }
        )
        store.exhaustivity = .off

        await store.send(.saveFailed) {
            $0.alert = .saveFailed()
        }
    }
}
