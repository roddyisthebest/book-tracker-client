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
    @Dependency(\.readingRecordService) var readingRecordService

    @ObservableState
    struct State: Equatable {
        var date: Date = .init()
        var monthlyReadingReport: MonthlyReadingReport?

        var isLoading: Bool = false
        var isError: Bool = false
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadData
        case loadDataResponse(Result<MonthlyReadingReport, AppError>)
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
                let year = components.year ?? Calendar.current.component(.year, from: Date())
                let month = components.month ?? Calendar.current.component(.month, from: Date())
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
                case .failure(let error):
                    state.isError = true
                }
                return .none
            }
        }
    }
}
