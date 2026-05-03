@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct HomeFeatureTests {
    @Test func onAppear_loadsRecentWeekAndBookCount() async {
        let store = TestStore(
            initialState: HomeFeature.State(),
            reducer: { HomeFeature() }
        )

        store.dependencies.readingRecordService.listRecentDaysByDate = { _ in .success([:]) }
        store.dependencies.localReceiptService.counts = { _ in .success([.purchase: 3, .rental: 1]) }
        store.exhaustivity = .off

        await store.send(.onAppear)

        await store.receive(\.loadRecentWeek)
        await store.receive(\.loadBookCount)

        // 비동기 응답은 완료 순서가 비결정적이므로 개별 테스트에서 검증
    }

    @Test func onAppear_subsequentCall_skipsRecentWeek() async {
        var state = HomeFeature.State()
        state.didInitialLoad = true

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )

        store.dependencies.localReceiptService.counts = { _ in .success([.purchase: 0, .rental: 0]) }
        store.exhaustivity = .off

        await store.send(.onAppear)
        // Only loadBookCount should fire, not loadRecentWeek
        await store.receive(\.loadBookCount)
        await store.receive(\.loadBookCountResponse)
    }

    @Test func doneButtonTapped_createsRecord() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let todayKey = Calendar.current.startOfDay(for: fixedDate)
        let record = TestFixtures.readingRecord

        let store = TestStore(
            initialState: HomeFeature.State(didReadToday: false),
            reducer: { HomeFeature() }
        )

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.readingRecordService.create = { _ in .success(record) }

        await store.send(.doneButtonTapped) {
            $0.isTodayRecordUpdating = true
        }

        await store.receive(\.createTodayResponse) {
            $0.isTodayRecordUpdating = false
            $0.didReadToday = true
            $0.todayRecordId = record.id
            $0.recentWeekRecords[todayKey] = record
        }
    }

    @Test func doneButtonTapped_deletesExistingRecord() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let todayKey = Calendar.current.startOfDay(for: fixedDate)
        let recordId = TestFixtures.readingRecord.id

        let store = TestStore(
            initialState: HomeFeature.State(
                didReadToday: true,
                todayRecordId: recordId
            ),
            reducer: { HomeFeature() }
        )

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.readingRecordService.delete = { _ in .success(()) }

        await store.send(.doneButtonTapped) {
            $0.isTodayRecordUpdating = true
        }

        await store.receive(\.deleteTodayResponse) {
            $0.isTodayRecordUpdating = false
            $0.didReadToday = false
            $0.todayRecordId = nil
            $0.recentWeekRecords[todayKey] = .some(nil)
        }
    }

    @Test func doneButtonTapped_whileUpdating_doesNothing() async {
        let store = TestStore(
            initialState: HomeFeature.State(isTodayRecordUpdating: true),
            reducer: { HomeFeature() }
        )

        await store.send(.doneButtonTapped)
    }

    @Test func createTodayFailed_showsAlert() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: HomeFeature.State(didReadToday: false),
            reducer: { HomeFeature() }
        )

        store.dependencies.date = .constant(fixedDate)
        store.dependencies.readingRecordService.create = { _ in
            .failure(.unknown(message: "fail"))
        }

        await store.send(.doneButtonTapped) {
            $0.isTodayRecordUpdating = true
        }

        await store.receive(\.createTodayFailed) {
            $0.destination = .alert(.showTodayReadingRecordUpdateError())
            $0.isTodayRecordUpdating = false
        }
    }

    @Test func loadRecentWeekFailed_setsError() async {
        let store = TestStore(
            initialState: HomeFeature.State(),
            reducer: { HomeFeature() }
        )

        store.dependencies.readingRecordService.listRecentDaysByDate = { _ in
            .failure(.unknown(message: "fail"))
        }

        await store.send(.loadRecentWeek) {
            $0.isRecentWeekLoading = true
            $0.hasRecordFetchingError = nil
        }

        await store.receive(\.loadRecentWeekFailed) {
            $0.isRecentWeekLoading = false
            $0.hasRecordFetchingError = true
            $0.recentWeekRecords = [:]
        }
    }

    @Test func bookSectionTapped_appendsPath() async {
        let store = TestStore(
            initialState: HomeFeature.State(),
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.bookSectionTapped(status: .reading)) {
            $0.path[id: 0] = .myBooks(MyBookListFeature.State(bookStatus: .reading))
        }
    }

    @Test func loadRecentWeekResponse_success_setsRecords() async {
        var state = HomeFeature.State()
        state.isRecentWeekLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )

        await store.send(.loadRecentWeekResponse([:])) {
            $0.isRecentWeekLoading = false
            $0.hasRecordFetchingError = false
            $0.recentWeekRecords = [:]
            $0.didReadToday = false
            $0.todayRecordId = nil
            $0.didInitialLoad = true
        }
    }

    @Test func loadBookCountResponse_success_setsCounts() async {
        var state = HomeFeature.State()
        state.isBookCountFetching = true

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )

        await store.send(.loadBookCountResponse(.success([.purchase: 3, .rental: 1]))) {
            $0.isBookCountFetching = false
            $0.purchaseBookCount = 3
            $0.rentalBookCount = 1
        }
    }

    @Test func deleteTodayFailed_showsAlert() async {
        let store = TestStore(
            initialState: HomeFeature.State(isTodayRecordUpdating: true),
            reducer: { HomeFeature() }
        )

        await store.send(.deleteTodayFailed) {
            $0.destination = .alert(.showTodayReadingRecordUpdateError())
            $0.isTodayRecordUpdating = false
        }
    }

    @Test func loadBookCount_failure_showsAlert() async {
        let store = TestStore(
            initialState: HomeFeature.State(),
            reducer: { HomeFeature() }
        )

        store.dependencies.localReceiptService.counts = { _ in .failure(.unknown) }

        await store.send(.loadBookCount) {
            $0.isBookCountFetching = true
        }

        await store.receive(\.loadBookCountResponse) {
            $0.isBookCountFetching = false
            $0.destination = .alert(.showBookCountsFetchingError())
        }
    }

    @Test func receiptIssueButtonTapped_presentsSelectBooks() async {
        let store = TestStore(
            initialState: HomeFeature.State(),
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.receiptIssueButtonTapped(type: .purchase)) {
            $0.destination = .selectBooks(ReceiptSelectBooksFeature.State(type: .purchase))
        }
    }

    @Test func myBooksButtonTapped_appendsPath() async {
        let store = TestStore(
            initialState: HomeFeature.State(),
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.myBooksButtonTapped) {
            $0.path[id: 0] = .myBooks(MyBookListFeature.State())
        }
    }

    @Test func selectBooksDelegate_receiptFlowCompleted_resetsPurchaseCount() async {
        var state = HomeFeature.State()
        state.purchaseBookCount = 5
        state.destination = .selectBooks(ReceiptSelectBooksFeature.State(type: .purchase))

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.selectBooks(.delegate(.receiptFlowCompleted(type: .purchase)))))) {
            $0.destination = nil
            $0.purchaseBookCount = 0
        }
    }

    @Test func selectBooksDelegate_receiptFlowCompleted_resetsRentalCount() async {
        var state = HomeFeature.State()
        state.rentalBookCount = 3
        state.destination = .selectBooks(ReceiptSelectBooksFeature.State(type: .rental))

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.selectBooks(.delegate(.receiptFlowCompleted(type: .rental)))))) {
            $0.destination = nil
            $0.rentalBookCount = 0
        }
    }

    @Test func selectBooksDelegate_removeBook_decrementsPurchaseCount() async {
        var state = HomeFeature.State()
        state.purchaseBookCount = 3
        state.destination = .selectBooks(ReceiptSelectBooksFeature.State(type: .purchase))

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.selectBooks(.delegate(.removeBook(id: "ext-001", type: .purchase)))))) {
            $0.purchaseBookCount = 2
        }
    }

    @Test func selectBooksDelegate_removeBook_decrementsRentalCount() async {
        var state = HomeFeature.State()
        state.rentalBookCount = 2
        state.destination = .selectBooks(ReceiptSelectBooksFeature.State(type: .rental))

        let store = TestStore(
            initialState: state,
            reducer: { HomeFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.selectBooks(.delegate(.removeBook(id: "ext-001", type: .rental)))))) {
            $0.rentalBookCount = 1
        }
    }
}
