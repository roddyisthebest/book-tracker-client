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
                guard let price = Int(state.price), price > 0 else {
                    state.alert = .showAddErrorAlert(message: "가격을 올바르게 입력해주세요.")
                    return .none
                }

                state.isLoading = true

                let receiptBook = state.externalBook.toReceiptBook(
                    type: .purchase,
                    price: price,
                    currencyCode: state.currencyCode.rawValue
                )

                print(receiptBook, "receiptBook")

                return .run { [book = receiptBook] send in
                    let result = await localReceiptService.saveReceiptBook(book)
                    await send(.addResponse(result))
                }

            case .addResponse(.success(let receiptBook)):
                state.isLoading = false
                state.alert = .showAddSuccessAlert(book: receiptBook)
                return .none

            case .addResponse(.failure):
                state.isLoading = false
                state.alert = .showAddErrorAlert(message: "가격 추가에 실패했어요. 다시 시도해주세요.")
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
            TextState("영수증에 추가되었습니다.")
        } actions: {
            ButtonState(role: .cancel, action: .confirmAdded(receiptBook: book)) {
                TextState("확인")
            }
        }
    }
}
