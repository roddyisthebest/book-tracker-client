@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ReadingReportFeatureTests {
    static let report = MonthlyReadingReport(
        month: MonthlyReadingReportMonth(
            year: 2026,
            month: 4,
            completedCount: 3,
            completedAverageScore: 4.2,
            purchaseCount: 2,
            purchaseAmount: 30_000,
            purchaseAmountCurrencyCode: "KRW",
            rentalCount: 1,
            unfinishedCount: 0,
            averageReadingDays: 7.5,
            paperCount: 2,
            ebookCount: 1,
            paperPercentage: 66.7,
            ebookPercentage: 33.3
        ),
        comparison: MonthlyReadingReportComparison(
            previousCompletedCount: 2,
            currentCompletedCount: 3,
            completedChangePercentage: 50.0,
            previousUnfinishedCount: 1,
            currentUnfinishedCount: 0,
            unfinishedChangePercentage: -100.0,
            previousPurchaseAmount: 20_000,
            currentPurchaseAmount: 30_000,
            purchaseAmountDifference: 10_000,
            purchaseAmountChangePercentage: 50.0,
            purchaseAmountCurrencyCode: "KRW",
            isPurchaseAmountIncreased: true,
            previousRentalCount: 0,
            currentRentalCount: 1,
            rentalCountChangePercentage: 100.0
        )
    )

    @Test func onAppear_loadsReport() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: ReadingReportFeature.State(date: fixedDate),
            reducer: { ReadingReportFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.readingRecordService.monthlyReport = { _, _ in .success(Self.report) }

        await store.send(.onAppear)
        await store.receive(\.loadData) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadDataResponse) {
            $0.loadingState = .loaded
            $0.monthlyReadingReport = Self.report
        }
    }

    @Test func loadData_failure_setsError() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: ReadingReportFeature.State(date: fixedDate),
            reducer: { ReadingReportFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.readingRecordService.monthlyReport = { _, _ in .failure(.unknown(message: "fail")) }

        await store.send(.loadData) {
            $0.loadingState = .loading
        }

        await store.receive(\.loadDataResponse) {
                        $0.loadingState = .error
        }
    }

    @Test func shareReady_presentsShare() async {
        let store = TestStore(
            initialState: ReadingReportFeature.State(),
            reducer: { ReadingReportFeature() }
        )

        await store.send(.shareReady("/tmp/report.png")) {
            $0.shareImagePath = "/tmp/report.png"
            $0.isSharePresented = true
        }
    }

    @Test func shareDismissed_hidesShare() async {
        var state = ReadingReportFeature.State()
        state.isSharePresented = true

        let store = TestStore(
            initialState: state,
            reducer: { ReadingReportFeature() }
        )

        await store.send(.shareDismissed) {
            $0.isSharePresented = false
        }
    }

    @Test func shareFailed_showsAlert() async {
        let store = TestStore(
            initialState: ReadingReportFeature.State(),
            reducer: { ReadingReportFeature() }
        )
        store.exhaustivity = .off

        await store.send(.shareFailed) {
            $0.alert = .shareFailed()
        }
    }

    @Test func shareButtonTapped_returnsNone() async {
        let store = TestStore(
            initialState: ReadingReportFeature.State(),
            reducer: { ReadingReportFeature() }
        )

        await store.send(.shareButtonTapped)
    }
}
