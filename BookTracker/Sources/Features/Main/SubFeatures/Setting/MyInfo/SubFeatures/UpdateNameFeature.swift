//
//  NameFieldFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation
import Sharing

@Reducer
struct UpdateNameFeature {
    @Dependency(\.myInfoService) var myInfoService

    @ObservableState
    struct State: Equatable {
        var isLoading: Bool = false

        @Shared(.userProfile) var profile: MyProfile?
        var name: String
        private var initialName: String
        var isSubmittable: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines) != initialName && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        @Presents var alert: AlertState<UpdateNameFeature.Action.Alert>?

        init(name: String = "") {
            self.name = name
            self.initialName = name
        }
    }

    enum Action: Equatable, BindableAction {
        case updateButtonTapped
        case binding(BindingAction<State>)

        case updateResponse(Result<MyProfile, AppError>)

        case delegate(Delegate)
        enum Delegate: Equatable {
            case didUpdate
        }

        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {}
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> {
            state, action in
            switch action {
            case .updateButtonTapped:
                state.isLoading = true
                let name = state.name
                return .run {
                    send in
                    let result = await myInfoService.updateName(name)
                    await send(.updateResponse(result))
                }
            case .updateResponse(.success(let profile)):
                state.isLoading = false
                state.$profile.withLock { $0 = profile }
                return .send(.delegate(.didUpdate))
            case .updateResponse(.failure(let error)):
                print(error, "error")
                state.isLoading = false
                state.alert = .showUpdateErrorAlert()
                return .none
            case .delegate:
                return .none
            case .binding:
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == UpdateNameFeature.Action.Alert {
    static func showUpdateErrorAlert() -> Self {
        Self {
            TextState("update_name_failed")
        }
    }
}
