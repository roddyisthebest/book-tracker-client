//
//  MyInfoFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation
import Sharing

enum LoginMethod: Equatable {
    case apple
    case google
    case local
}

@Reducer
struct MyInfoFeature {
    @Dependency(\.myInfoService) var myInfoService

    @ObservableState
    struct State: Equatable {
        @Shared(.userProfile) var profile: MyProfile?
        @SharedReader(.userAuthInfo) var authInfo: MyAuthInfo?

        var isUpdatingImage: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case nameEditButtonTapped
        case profileImageViewTapped
        case updateImageUuidResponse(Result<MyProfile, AppError>)

        case destination(PresentationAction<Destination.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .nameEditButtonTapped:
                state.destination = .updateName(UpdateNameFeature.State(name: state.profile?.name ?? ""))
                return .none
            case .profileImageViewTapped:
                guard !state.isUpdatingImage else { return .none }
                state.isUpdatingImage = true
                let newUuid = UUID()
                return .run { send in
                    let result = await myInfoService.updateImageUuid(newUuid)
                    await send(.updateImageUuidResponse(result))
                }
            case .updateImageUuidResponse(.success(let profile)):
                state.isUpdatingImage = false
                state.$profile.withLock { $0 = profile }
                return .none
            case .updateImageUuidResponse(.failure):
                state.isUpdatingImage = false
                return .none
            case .destination(.presented(.updateName(.delegate(.didUpdate)))):
                state.destination = nil
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension MyInfoFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case updateName(UpdateNameFeature)
    }
}
