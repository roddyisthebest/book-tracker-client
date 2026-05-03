@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct StatFeatureTests {
    @Test func navigateToDoneBookCalendar_appendsPath() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: StatFeature.State(),
            reducer: { StatFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)

        await store.send(.navigateButtonTapped(.doneBookCalandar)) {
            $0.path[id: 0] = .doneBookCalandar(DoneBooksCalendarFeature.State(date: fixedDate))
        }
    }

    @Test func navigateToReadingTracker_appendsPath() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: StatFeature.State(),
            reducer: { StatFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)

        await store.send(.navigateButtonTapped(.readingTrakcer)) {
            $0.path[id: 0] = .readingCalendar(ReadingCalendarFeature.State(date: fixedDate))
        }
    }

    @Test func navigateToReadingReport_appendsPath() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: StatFeature.State(),
            reducer: { StatFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)

        await store.send(.navigateButtonTapped(.readingReport)) {
            $0.path[id: 0] = .readingReport(ReadingReportFeature.State(date: fixedDate))
        }
    }
}
