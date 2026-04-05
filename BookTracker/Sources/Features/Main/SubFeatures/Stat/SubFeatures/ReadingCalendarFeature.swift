//
//  ReadingCalendarFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ReadingCalendarFeature {
    @Dependency(\.readingRecordService) var readingRecordService

    @ObservableState
    struct State: Equatable {
        var date: Date = .init()

        var isLoading: Bool = false
        var isError: Bool = false

        var readingRecords: [Date: ReadingRecord?]?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadData
        case loadDataResponse(Result<[Date: ReadingRecord?], AppError>)
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
                state.readingRecords = nil
                let calendar = Calendar(identifier: .gregorian)
                let comps = calendar.dateComponents([.year, .month], from: state.date)
                let year = comps.year ?? calendar.component(.year, from: Date())
                let month = comps.month ?? calendar.component(.month, from: Date())
                return .run { send in
                    let result = await readingRecordService.listByMonthByDate(year, month)
                    await send(.loadDataResponse(result))
                }
            case .loadDataResponse(let result):
                state.isLoading = false
                switch result {
                case .success(let data):
                    state.readingRecords = data
                case .failure:
                    state.isError = true
                }
                return .none
            }
        }
    }
}
