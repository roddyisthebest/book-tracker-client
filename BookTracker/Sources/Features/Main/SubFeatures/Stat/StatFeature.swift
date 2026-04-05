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
            case doneBookCalandar
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
                case .doneBookCalandar:
                    state.path.append(.doneBookCalandar(DoneBooksCalendarFeature.State()))
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
            case doneBookCalandar(DoneBooksCalendarFeature.State = .init())
        }

        enum Action: Equatable {
            case readingCalendar(ReadingCalendarFeature.Action)
            case readingReport(ReadingReportFeature.Action)
            case doneBookCalendar(DoneBooksCalendarFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: \.readingCalendar, action: \.readingCalendar) {
                ReadingCalendarFeature()
            }

            Scope(state: \.readingReport, action: \.readingReport) {
                ReadingReportFeature()
            }

            Scope(state: \.doneBookCalandar, action: \.doneBookCalendar) {
                DoneBooksCalendarFeature()
            }
        }
    }
}
