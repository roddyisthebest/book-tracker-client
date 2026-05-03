//
//  ResetDataFeature.swift
//  BookTracker
//
//  Created by 배성연 on 4/25/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ResetDataFeature {
    @Dependency(\.searchHistory) var searchHistory
    @Dependency(\.localReceiptService) var localReceiptService
    @Dependency(\.localCustomBookService) var localCustomBookService
    @Dependency(\.authService) var authService
    @Shared(.userProfile) var profile: MyProfile?

    @ObservableState
    struct State: Equatable {
        var isAppDataDeleting: Bool = false
        var isServerDataDeleting: Bool = false
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case deleteAppDataTapped
        case deleteServerDataTapped
        case confirmDeleteAppData
        case confirmDeleteServerData
        case deleteAppDataResponse(Result<Bool, AppError>)
        case deleteServerDataResponse(Result<Bool, AppError>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmDeleteAppData
            case confirmDeleteServerData
        }

        enum Delegate: Equatable {
            case appDataDeleted
            case serverDataDeleted
        }
    }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .deleteAppDataTapped:
                state.alert = .confirmDeleteAppData()
                return .none

            case .deleteServerDataTapped:
                state.alert = .confirmDeleteServerData()
                return .none

            case .confirmDeleteAppData:
                state.isAppDataDeleting = true
                let userId = profile?.id.uuidString ?? ""
                return .run { [searchHistory, localReceiptService, localCustomBookService] send in
                    do {
                        try await searchHistory.clearAll(userId)
                        let receiptResult = await localReceiptService.clearAll(userId)
                        _ = await localCustomBookService.clearAll(userId)
                        switch receiptResult {
                        case .success:
                            await send(.deleteAppDataResponse(.success(true)))
                        case .failure:
                            await send(.deleteAppDataResponse(.failure(.unknown(message: "Failed to clear receipt data"))))
                        }
                    } catch {
                        await send(.deleteAppDataResponse(.failure(.unknown(message: error.localizedDescription))))
                    }
                }

            case .confirmDeleteServerData:
                state.isServerDataDeleting = true
                return .run { [authService] send in
                    let result = await authService.deleteMyAppData()
                    switch result {
                    case .success:
                        await send(.deleteServerDataResponse(.success(true)))
                    case .failure(let error):
                        await send(.deleteServerDataResponse(.failure(error)))
                    }
                }

            case .deleteAppDataResponse(.success):
                state.isAppDataDeleting = false
                state.alert = .appDataDeleteSuccess()
                return .send(.delegate(.appDataDeleted))

            case .deleteAppDataResponse(.failure):
                state.isAppDataDeleting = false
                state.alert = .appDataDeleteFailed()
                return .none

            case .deleteServerDataResponse(.success):
                state.isServerDataDeleting = false
                state.alert = .serverDataDeleteSuccess()
                return .send(.delegate(.serverDataDeleted))

            case .deleteServerDataResponse(.failure):
                state.isServerDataDeleting = false
                state.alert = .serverDataDeleteFailed()
                return .none

            case .alert(.presented(.confirmDeleteAppData)):
                return .send(.confirmDeleteAppData)

            case .alert(.presented(.confirmDeleteServerData)):
                return .send(.confirmDeleteServerData)

            case .alert:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == ResetDataFeature.Action.Alert {
    static func confirmDeleteAppData() -> Self {
        Self {
            TextState("confirm_delete_app_data")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteAppData) {
                TextState("delete")
            }
        } message: {
            TextState("confirm_delete_app_data_message")
        }
    }

    static func confirmDeleteServerData() -> Self {
        Self {
            TextState("confirm_delete_server_data")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeleteServerData) {
                TextState("delete")
            }
        } message: {
            TextState("confirm_delete_server_data_message")
        }
    }

    static func appDataDeleteSuccess() -> Self {
        Self {
            TextState("delete_success")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        } message: {
            TextState("app_data_delete_success_message")
        }
    }

    static func appDataDeleteFailed() -> Self {
        Self {
            TextState("delete_failed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        } message: {
            TextState("delete_failed_message")
        }
    }

    static func serverDataDeleteSuccess() -> Self {
        Self {
            TextState("delete_success")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        } message: {
            TextState("server_data_delete_success_message")
        }
    }

    static func serverDataDeleteFailed() -> Self {
        Self {
            TextState("delete_failed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("confirm")
            }
        } message: {
            TextState("delete_failed_message")
        }
    }
}
