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
    @ObservableState
    struct State: Equatable {
        var date: Date = .init()
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { _, action in
            switch action {
            case .binding:
                return .none
            }
        }
    }
}
