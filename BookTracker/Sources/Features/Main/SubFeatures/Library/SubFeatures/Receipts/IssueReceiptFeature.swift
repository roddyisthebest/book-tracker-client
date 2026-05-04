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
    @Shared(.userId) var userId: String?

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

        var totalMicros: Int64 {
            receiptBooks.reduce(Int64(0)) { $0 + ($1.saleInfo?.amountInMicros ?? 0) }
        }

        var totalUsdMicros: Int64 {
            receiptBooks.reduce(Int64(0)) { sum, book in
                let micros = book.saleInfo?.amountInMicros ?? 0
                let currency = book.saleInfo?.currencyCode ?? .krw
                return sum + CurrencyCode.convertMicros(micros, from: currency, to: .usd)
            }
        }
    }

    enum Action: Equatable, BindableAction {
        case issueButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case issueReceiptCompleted
        }

        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmCreation
        }

        case createResponse(Result<UUID, AppError>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce<State, Action> {
            state, action in
            switch action {
            case .issueButtonTapped:
                let source = state.source
                let totalMicros: Int64 = state.type == .purchase
                    ? (Int64(state.price).map { $0 * CurrencyCode.microsPerUnit } ?? state.totalMicros)
                    : 0
                let totalUsdMicros: Int64? = state.type == .purchase ? state.totalUsdMicros : nil
                let type = state.type
                let items = state.receiptBooks.map { $0.toReceiptRpcItem() }
                let receiptAt = state.receiptAt
                state.isLoading = true
                return .run {
                    send in
                    let result = await receiptService.createReceiptWithBooks(source, totalMicros, totalUsdMicros, type, receiptAt, items)
                    await send(.createResponse(result))
                }
            case .createResponse(.success):
                state.isLoading = false
                state.alert = .showCreationSuccessAlert()
                return .none
            case .createResponse(.failure(let error)):
                print(error)
                state.isLoading = false
                state.alert = .showCreationErrorAlert()
                return .none
            case .alert(.presented(.confirmCreation)):
                let type = state.type
                let userId = userId ?? ""
                return .run {
                    send in
                    let _ = await localReceiptService.removeSpecificTypes(userId, type)
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
