//
//  Untitled.swift
//  BookTracker
//
//  Created by 배성연 on 2/20/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct IssueReceiptFeature {
    @Dependency(\.receiptService) var receiptService
    @Dependency(\.localReceiptService) var localReceiptService

    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<IssueReceiptFeature.Action.Alert>?

        var isLoading: Bool = false

        var receiptBooks: [ReceiptBook] = []
        var type: ReceiptType = .rental

        // common
        var source: String = ""
        var receiptAt: Date = .init()

        // .purchase
        var price: String = ""

        var totalPrice: Int {
            receiptBooks.reduce(0) { $0 + ($1.saleInfo?.amountInMicros ?? 0) } / 1_000_000
        }
    }

    enum Action: Equatable, BindableAction {
        case issueButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case issueReceiptCompleted
        }

        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmCreation
        }

        case createResponse(Result<CreateReceiptWithBooksResult, AppError>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> {
            state, action in
            switch action {
            case .issueButtonTapped:
                let source = state.source
                let totalPrice = state.type == .purchase ? Int(state.price) ?? state.totalPrice : 0
                let type = state.type
                let items = state.receiptBooks.map { $0.toReceiptRpcItem() }
                let receiptAt = state.receiptAt
                state.isLoading = true
                return .run {
                    send in
                    let result = await receiptService.createReceiptWithBooks(source, totalPrice, type, receiptAt, items)
                    await send(.createResponse(result))
                }
            case .createResponse(.success):
                state.isLoading = false
                state.alert = .showCreationSuccessAlert()
                return .none
            case .createResponse(.failure):
                state.isLoading = false
                state.alert = .showCreationErrorAlert()
                return .none
            case .alert(.presented(.confirmCreation)):
                let type = state.type
                return .run {
                    send in
                    let _ = await localReceiptService.removeSpecificTypes(type)
                    await send(.delegate(.issueReceiptCompleted))
                }
            case .binding:
                return .none
            case .delegate:
                return .none
            case .alert:
                return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == IssueReceiptFeature.Action.Alert {
    static func showCreationErrorAlert() -> Self {
        Self {
            TextState("receipt_create_failed")
        }
    }

    static func showCreationSuccessAlert() -> Self {
        Self {
            TextState("receipt_issued_success")
        }
        actions: {
            ButtonState(role: .cancel, action: .confirmCreation) {
                TextState("confirm")
            }
        }
    }
}
