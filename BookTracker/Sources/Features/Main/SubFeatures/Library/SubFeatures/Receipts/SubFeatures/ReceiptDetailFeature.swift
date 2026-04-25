//
//  ReceiptDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ReceiptDetailFeature {
    @Dependency(\.receiptService) var receiptService
    @Dependency(\.localeService) var localeService

    @ObservableState
    struct State: Equatable {
        let id: UUID

        var detail: ReceiptDetail? = nil
        var targetCurrency: CurrencyCode?

        var isLoading: Bool = false
        var isError: Bool = false
        var isDeleting: Bool = false

        @Presents var alert: AlertState<ReceiptDetailFeature.Action.Alert>?
    }

    enum Action: Equatable {
        case onAppear
        case onRefresh

        case loadReceipt
        case loadReceiptResponse(Result<ReceiptDetail, AppError>)

        case currencyChanged(CurrencyCode)
        case deleteButtonTapped
        case deleteResponse(Result<Bool, AppError>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        enum Alert: Equatable {
            case confirmDeletion
        }

        enum Delegate: Equatable {
            case deleteReceipt(UUID)
        }
    }

    private enum CancelID { case loadReceipt }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.targetCurrency = localeService.currencyForLocale()
                return .send(.loadReceipt)
            case .onRefresh:
                return .send(.loadReceipt)
            case .loadReceipt:
                state.isLoading = true
                state.isError = false
                return .run { [id = state.id] send in
                    let result = await receiptService.loadReceiptDetail(id)
                    await send(.loadReceiptResponse(result))
                }
                .cancellable(id: CancelID.loadReceipt, cancelInFlight: true)
            case .loadReceiptResponse(.success(let detail)):
                state.isLoading = false
                state.isError = false
                state.detail = detail
                print(detail, "detail")
                return .none
            case .loadReceiptResponse(.failure(let error)):
                state.isLoading = false
                state.isError = true
                return .none
            case .currencyChanged(let currency):
                state.targetCurrency = currency
                return .none
            case .deleteButtonTapped:
                state.alert = AlertState {
                    TextState("are_you_sure")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("delete")
                    }
                }
                return .none
            case .alert(.presented(.confirmDeletion)):
                state.alert = nil
                state.isDeleting = true
                return .run { [id = state.id] send in
                    let result = await receiptService.deleteReceipt(id)
                    switch result {
                    case .success:
                        await send(.deleteResponse(.success(true)))
                    case .failure(let error):
                        await send(.deleteResponse(.failure(error)))
                    }
                }
            case .deleteResponse(.success):
                state.isDeleting = false
                return .run { [id = state.id] send in
                    await send(.delegate(.deleteReceipt(id)))
                }
            case .deleteResponse(.failure(let error)):
                state.isDeleting = false
                state.alert = AlertState {
                    TextState("delete_failed")
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none
            case .alert:
                return .none
            case .delegate:
                return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }
}
