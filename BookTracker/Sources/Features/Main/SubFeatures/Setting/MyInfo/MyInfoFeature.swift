//
//  MyInfoFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/22/26.
//

import ComposableArchitecture
import Foundation

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
        var profile: MyProfile?

        var email: String?
        var loginMethod: LoginMethod?

        var myAuthInfo: MyAuthInfo?

        var isFetching: Bool = false
        var isError: Bool = false
        var isUpdatingImage: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case nameEditButtonTapped
        case profileImageViewTapped
        case updateImageUuidResponse(Result<MyProfile, AppError>)

        case onAppear
        case onRefresh
        case loadAuthInfo
        case loadAuthInfoResponse(Result<MyAuthInfo, AppError>)

        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case updateProfile(MyProfile)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> {
            state, action in
            switch action {
            case .onAppear:
                return .send(.loadAuthInfo)
            case .onRefresh:
                return .send(.onAppear)
            case .loadAuthInfo:
                state.isFetching = true
                state.isError = false
                return .run { send in
                    let result = await myInfoService.loadAuthInfo()
                    await send(.loadAuthInfoResponse(result))
                }
            case .loadAuthInfoResponse(.success(let myAuthInfo)):
                state.isFetching = false
                state.myAuthInfo = myAuthInfo
                return .none
            case .loadAuthInfoResponse(.failure):
                state.isFetching = false
                state.isError = true
                state.myAuthInfo = nil
                return .none
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
                state.profile = profile
                return .send(.delegate(.updateProfile(profile)))
            case .updateImageUuidResponse(.failure):
                state.isUpdatingImage = false
                return .none
            case .destination(.presented(.updateName(.delegate(.updateProfile(let profile))))):
                state.destination = nil
                state.profile = profile
                return .none
            case .destination:
                return .none
            case .delegate:
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
