//
//  AddPriceFeature.swift
//  BookTracker
//
//  Created by 배성연 on 3/29/26.
//
import ComposableArchitecture
import Foundation

@Reducer
struct AddPriceFeature {
    @Dependency(\.localReceiptService) var localReceiptService
    @Shared(.userProfile) var profile: MyProfile?

    @ObservableState
    struct State: Equatable {
        var externalBook: ExternalBook
        var isLoading: Bool = false

        /// 숫자만 저장
        var price: String = ""
        var currencyCode: CurrencyCode = .krw

        var isValid: Bool {
            guard let value = Int(price), value > 0 else { return false }
            return true
        }

        @Presents var alert: AlertState<AddPriceFeature.Action.Alert>?
    }

    enum Action: Equatable, BindableAction {
        case addButtonTapped
        case addResponse(Result<ReceiptBook, LocalReceiptError>)
        case binding(BindingAction<State>)

        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {
            case confirmAdded(receiptBook: ReceiptBook)
        }

        case delegate(Delegate)
        enum Delegate: Equatable {
            case addBookToReceipt(receiptBook: ReceiptBook)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .addButtonTapped:
                guard let price = Int64(state.price), price > 0 else {
                    state.alert = .showAddErrorAlert(message: String(localized: "invalid_price_message"))
                    return .none
                }

                state.isLoading = true
                let amountInMicros = price * CurrencyCode.microsPerUnit

                let receiptBook = state.externalBook.toReceiptBook(
                    type: .purchase,
                    amountInMicros: amountInMicros,
                    currencyCode: state.currencyCode
                )

                let userId = profile?.id.uuidString ?? ""
                return .run { [book = receiptBook] send in
                    let result = await localReceiptService.saveReceiptBook(userId, book)
                    await send(.addResponse(result))
                }

            case .addResponse(.success(let receiptBook)):
                state.isLoading = false
                state.alert = .showAddSuccessAlert(book: receiptBook)
                return .none

            case .addResponse(.failure):
                state.isLoading = false
                state.alert = .showAddErrorAlert(message: String(localized: "price_add_failed"))
                return .none

            case .alert(.presented(.confirmAdded(let receiptBook))):
                return .send(.delegate(.addBookToReceipt(receiptBook: receiptBook)))

            case .alert:
                return .none

            case .binding:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == AddPriceFeature.Action.Alert {
    static func showAddErrorAlert(message: String) -> Self {
        Self {
            TextState(message)
        }
    }

    static func showAddSuccessAlert(book: ReceiptBook) -> Self {
        Self {
            TextState("added_to_receipt")
        } actions: {
            ButtonState(role: .cancel, action: .confirmAdded(receiptBook: book)) {
                TextState("confirm")
            }
        }
    }
}
