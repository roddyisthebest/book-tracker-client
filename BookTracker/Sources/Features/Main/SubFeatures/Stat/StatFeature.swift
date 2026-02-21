//
//  StatFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/21/26.
//

import ComposableArchitecture

@Reducer
struct StatFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
    }

    enum Action: Equatable {
        case navigateButtonTapped(PathCase)
        case path(StackAction<Path.State, Path.Action>)

        enum PathCase: Equatable {
            case readingCalendar
            case readingTrakcer
            case readingReport
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .navigateButtonTapped(let path):
                switch path {
                case .readingCalendar:
                    state.path.append(.readingCalendar(ReadingCalendarFeature.State()))
                case .readingReport:
                    state.path.append(.readingReport(ReadingReportFeature.State()))
                case .readingTrakcer:
                    state.path.append(.readingCalendar(ReadingCalendarFeature.State()))
                }

                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
    }
}

extension StatFeature {
    @Reducer
    struct Path: Equatable {
        @ObservableState
        enum State: Equatable {
            case readingCalendar(ReadingCalendarFeature.State = .init())
            case readingReport(ReadingReportFeature.State = .init())
        }

        enum Action: Equatable {
            case readingCalendar(ReadingCalendarFeature.Action)
            case readingReport(ReadingReportFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.readingCalendar, action: \.readingCalendar) {
                ReadingCalendarFeature()
            }

            Scope(state: \.readingReport, action: \.readingReport) {
                ReadingReportFeature()
            }
        }
    }
}
