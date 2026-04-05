//
//  HomeFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/19/26.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct HomeFeature {
    private var todayKey: Date {
        Calendar.current.startOfDay(for: Date())
    }

    @Dependency(\.readingRecordService) var readingRecordService
    @Dependency(\.localReceiptService) var localReceiptService

    @ObservableState
    struct State: Equatable {
        var books: [Book] = []

        var didReadToday: Bool? = nil
        var todayRecordId: UUID? = nil

        var isTodayRecordUpdating: Bool = false // toggling create/delete

        var hasRecordFetchingError: Bool? = nil

        var recentWeekRecords: [Date: ReadingRecord?] = [:]
        var isRecentWeekLoading: Bool = false

        var purchaseBookCount: Int = 0
        var rentalBookCount: Int = 0

        var isBookCountFetching: Bool = false

        var path = StackState<Path.State>()

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case doneButtonTapped
        case bookSectionTapped(status: BookStatus)
        case receiptIssueButtonTapped(type: ReceiptType)
        case myBooksButtonTapped

        case createTodayResponse(ReadingRecord)
        case createTodayFailed
        case deleteTodayResponse
        case deleteTodayFailed

        case onAppear

        case loadRecentWeek
        case loadRecentWeekResponse([Date: ReadingRecord?])
        case loadRecentWeekFailed

        case loadBookCount
        case loadBookCountResponse(Result<[ReceiptType: Int], LocalReceiptError>)

        case path(StackAction<Path.State, Path.Action>)
        case destination(PresentationAction<Destination.Action>)

        enum Alert: Equatable {
            case confirmError
        }
    }

    private enum CancelID { case loadToday, toggle, loadRecentWeek }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadRecentWeek),
                    .send(.loadBookCount)
                )

            case .doneButtonTapped:
                // Toggle today's reading record: if exists, delete; otherwise create
                if state.isTodayRecordUpdating { return .none }
                state.isTodayRecordUpdating = true
                if state.didReadToday == true, let id = state.todayRecordId {
                    return .run { [readingRecordService] send in
                        let result = try await readingRecordService.delete(id)

                        switch result {
                        case .success:
                            await send(.deleteTodayResponse)
                        case .failure:
                            await send(.deleteTodayFailed)
                        }
                    }
                    .cancellable(id: CancelID.toggle, cancelInFlight: true)
                } else {
                    return .run { [readingRecordService] send in
                        let result = try await readingRecordService.create(Date())
                        switch result {
                        case .success(let record):
                            await send(.createTodayResponse(record))
                        case .failure:
                            await send(.createTodayFailed)
                        }
                    }
                    .cancellable(id: CancelID.toggle, cancelInFlight: true)
                }

            case .bookSectionTapped(let status):
                state.path.append(.myBooks(MyBookListFeature.State(bookStatus: status)))
                return .none

            case .receiptIssueButtonTapped(let type):
                state.destination = .selectBooks(ReceiptSelectBooksFeature.State(type: type))
                return .none

            case .myBooksButtonTapped:
                state.path.append(.myBooks(MyBookListFeature.State()))
                return .none

            case .createTodayResponse(let record):
                state.isTodayRecordUpdating = false
                state.didReadToday = true
                state.todayRecordId = record.id
                state.recentWeekRecords[todayKey] = record

                return .none

            case .createTodayFailed:
                state.destination = .alert(.showTodayReadingRecordUpdateError())
                state.isTodayRecordUpdating = false
                return .none

            case .deleteTodayResponse:
                state.isTodayRecordUpdating = false
                state.didReadToday = false
                state.todayRecordId = nil
                state.recentWeekRecords[todayKey] = .some(nil)

                return .none

            case .deleteTodayFailed:
                state.destination = .alert(.showTodayReadingRecordUpdateError())
                state.isTodayRecordUpdating = false
                return .none

            case .loadRecentWeek:
                state.isRecentWeekLoading = true
                state.hasRecordFetchingError = nil
                return .run { [readingRecordService] send in
                    let result = try await readingRecordService.listRecentDaysByDate(7)
                    switch result {
                    case .success(let records):
                        await send(.loadRecentWeekResponse(records))
                    case .failure:
                        await send(.loadRecentWeekFailed)
                    }
                }
                .cancellable(id: CancelID.loadRecentWeek, cancelInFlight: true)

            case .loadBookCount:
                state.isBookCountFetching = true
                return .run {
                    send in
                    let result = await localReceiptService.counts()
                    await send(.loadBookCountResponse(result))
                }

            case .loadBookCountResponse(let result):
                state.isBookCountFetching = false
                switch result {
                case .success(let arr):
                    state.purchaseBookCount = arr[.purchase] ?? 0
                    state.rentalBookCount = arr[.rental] ?? 0
                case .failure:
                    state.destination = .alert(.showBookCountsFetchingError())
                }

                return .none

            case .loadRecentWeekResponse(let records):
                state.isRecentWeekLoading = false
                state.hasRecordFetchingError = false
                state.recentWeekRecords = records
                let todayRecord = records.values.first {
                    guard let record = $0 else { return false }
                    return Calendar.current.isDateInToday(record.date)
                }

                state.didReadToday = todayRecord != nil
                state.todayRecordId = todayRecord??.id

                return .none

            case .loadRecentWeekFailed:
                state.isRecentWeekLoading = false
                state.hasRecordFetchingError = true
                state.recentWeekRecords = [:]
                return .none

            case .destination(.presented(.selectBooks(.delegate(.receiptFlowCompleted(let type))))):
                state.destination = nil
                if type == .purchase {
                    state.purchaseBookCount = 0
                } else {
                    state.rentalBookCount = 0
                }

                return .none

            case .destination(.presented(.selectBooks(.delegate(.removeBook(_, let type))))):
                if type == .purchase {
                    state.purchaseBookCount = max(0, state.purchaseBookCount - 1)
                } else {
                    state.rentalBookCount = max(0, state.rentalBookCount - 1)
                }

                return .none

            case .destination(.presented(.selectBooks(.destination(.presented(.search(.detailSheet(.presented(.delegate(.addBookToReceipt(let book)))))))))):
                if book.type == .purchase {
                    state.purchaseBookCount += 1

                } else {
                    state.rentalBookCount += 1
                }
                return .none

            case .path:
                return .none

            case .destination:
                return .none
            }
        }

        .forEach(\.path, action: \.path) {
            Path()
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension HomeFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case myBooks(MyBookListFeature.State = .init())
        }

        enum Action: Equatable {
            case myBooks(MyBookListFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.myBooks, action: \.myBooks) {
                MyBookListFeature()
            }
        }
    }
}

extension HomeFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case selectBooks(ReceiptSelectBooksFeature)
        case alert(AlertState<HomeFeature.Action.Alert>)
    }
}

extension AlertState where Action == HomeFeature.Action.Alert {
    static func showTodayReadingRecordUpdateError() -> Self {
        Self {
            TextState("오늘 독서 기록 처리 중 오류가 발생했어요.")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        }
    }

    static func showBookCountsFetchingError() -> Self {
        Self {
            TextState("영수증, 대출증 등의 정보를 가져오는 중 오류가 발생했어요. ")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("확인")
            }
        }
    }
}
