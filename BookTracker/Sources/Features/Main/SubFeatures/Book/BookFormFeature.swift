//
//  BookFormFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/12/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct BookFormFeature {
    @ObservableState
    struct State: Equatable {
        let externalId: String

        let bookId: UUID?

        var title: String = ""
        var status: BookStatus = .done
        var type: BookType = .paper

        var progress: Double = 0.0
        var page: String = "0"
        var entirePage: Int = 216

        var rating: Double = 0.0
        var startedAt: Date = .init()
        var endedAt: Date = .init()

        var reason: String = ""
        var note: String = ""
        var reviewComment: String = ""
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case addButtonTapped
        case saveButtonTapped

        case delegate(Delegate)

        enum Delegate: Equatable {
            case confirmCreation(Book)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> { state, action in
            switch action {
            case .addButtonTapped:
                return .none
            case .saveButtonTapped:
                return .none
            case .binding(\.progress):
                let pageValue = Double(max(state.entirePage, 0)) * (max(state.progress, 0) * 0.01)
                let pageInt = Int(pageValue)
                state.page = String(pageInt)
                return .none
            case .binding(\.page):
                if let pageInt = Int(state.page) {
                    let page = min(max(pageInt, 0), state.entirePage)
                    let progress = (Double(page) / max(Double(state.entirePage), 1.0)) * 100.0
                    state.progress = progress
                } else {
                    state.progress = 0
                }
                return .none
            case .binding:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

extension BookFormFeature.State {
    var isEditing: Bool { bookId != nil }
}
