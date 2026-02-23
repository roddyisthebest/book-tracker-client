//
//  DataManageFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture

@Reducer
struct DataManageFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case csvExportButtonTapped
        case dataResetButtonTapped
        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmResetData
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .csvExportButtonTapped:
                return .none
            case .dataResetButtonTapped:
                state.alert = .confirmResetData()
                return .none
            case .alert(.presented(.confirmResetData)):
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == DataManageFeature.Action.Alert {
    static func confirmResetData() -> Self {
        Self {
            TextState("정말 데이터를 리셋하시겠습니까?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmResetData) {
                TextState("리셋하기")
            }
        }
    }
}
