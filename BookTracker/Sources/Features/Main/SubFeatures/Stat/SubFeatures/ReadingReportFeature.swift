//
//  ReadingReportFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//
import ComposableArchitecture
import Foundation

@Reducer
struct ReadingReportFeature {
    @Dependency(\.date) var date
    @Dependency(\.readingRecordService) var readingRecordService

    @ObservableState
    struct State: Equatable {
        var date: Date = .init()
        var monthlyReadingReport: MonthlyReadingReport?

        var isLoading: Bool = false
        var isError: Bool = false

        @Presents var alert: AlertState<Action.Alert>?
        var isSharePresented: Bool = false
        var shareImagePath: String? = nil
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadData
        case loadDataResponse(Result<MonthlyReadingReport, AppError>)
        case shareButtonTapped
        case shareReady(String)
        case shareFailed
        case shareDismissed
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {}
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.date):
                return .send(.loadData)
            case .binding:
                return .none
            case .onAppear:
                return .send(.loadData)
            case .loadData:
                state.isLoading = true
                state.isError = false
                let components = Calendar.current.dateComponents([.year, .month], from: state.date)
                let year = components.year ?? Calendar.current.component(.year, from: date.now)
                let month = components.month ?? Calendar.current.component(.month, from: date.now)
                print("year", year)
                print("month", month)

                return .run {
                    send in
                    let result = await readingRecordService.monthlyReport(year, month)
                    await send(.loadDataResponse(result))
                }
            case .loadDataResponse(let result):
                state.isLoading = false
                switch result {
                case .success(let data):
                    state.monthlyReadingReport = data
                case .failure:
                    state.isError = true
                }
                return .none
            case .shareButtonTapped:
                return .none
            case .shareReady(let path):
                state.shareImagePath = path
                state.isSharePresented = true
                return .none
            case .shareFailed:
                state.alert = .shareFailed()
                return .none
            case .shareDismissed:
                state.isSharePresented = false
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == ReadingReportFeature.Action.Alert {
    static func shareFailed() -> Self {
        Self {
            TextState("share_failed")
        } actions: {
            ButtonState(role: .cancel) { TextState("confirm") }
        } message: {
            TextState("share_failed_message")
        }
    }
}
