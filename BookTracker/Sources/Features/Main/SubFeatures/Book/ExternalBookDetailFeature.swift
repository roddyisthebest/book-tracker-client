//
//  ExternalBookDetailFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/16/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct ExternalBookDetailFeature {
    @Dependency(\.date) var date
    @Dependency(\.externalBookService) var bookService
    @Dependency(\.bookService) var myBookService
    @Dependency(\.localReceiptService) var localReceiptService
    @Shared(.userProfile) var profile: MyProfile?

    @ObservableState
    struct State: Equatable {
        let id: String
        var book: ExternalBook? = nil
        var isAlreadyRegistered: Bool? = nil

        var isLoading: Bool = false
        var errorMessage: String? = nil

        var isExtended: Bool = false
        var isExtendable: Bool = false

        var registeredReceiptTypes: [ReceiptType] = []

        var isRegisteredReceiptTypesLoading: Bool = false
        var isRegisteredReceiptTypesLoadError: Bool = false
        var isRegisteredReceiptTypesLoadSuccess: Bool = false

        var isPurchasingSaving: Bool = false
        var isRentalSaving: Bool = false

        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        enum AddType: Equatable {
            case purchase
            case rental
            case mybooks(externalId: String)
        }

        case onAppear

        case loadReceiptTypes
        case loadReceiptTypesResponse(Result<[ReceiptType], LocalReceiptError>)

        case saveReceiptResponse(Result<ReceiptType, LocalReceiptError>)

        case loadDetail
        case detailResponse(Result<ExternalBook, ExternalBookService.ServiceError>)
        case checkAlreadyRegistered
        case alreadyRegisteredResponse(Result<Bool, AppError>)
        case addButtonTapped(AddType)
        case extendButtonTapped

        case destination(PresentationAction<Destination.Action>)
        enum Alert: Equatable {
            case confirmReceipt
            case confirmRental
            case addPrice
        }

        case delegate(Delegate)
        enum Delegate: Equatable {
            case addBookToReceipt(receiptBook: ReceiptBook, type: ReceiptType)
        }
    }

    private enum CancelID { case fetch, check }

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .send(.loadDetail),
                    .send(.loadReceiptTypes),
                    .send(.checkAlreadyRegistered)
                )
            case .loadReceiptTypes:
                state.isRegisteredReceiptTypesLoading = true
                state.isRegisteredReceiptTypesLoadError = false
                state.isRegisteredReceiptTypesLoadSuccess = false
                let bookId = state.id
                let userId = profile?.id.uuidString ?? ""
                return .run {
                    send in
                    let result = await localReceiptService.registeredTypes(userId, bookId)
                    await send(.loadReceiptTypesResponse(result))
                }
            case .loadReceiptTypesResponse(.success(let receiptTypes)):
                state.isRegisteredReceiptTypesLoading = false
                state.isRegisteredReceiptTypesLoadSuccess = true
                state.registeredReceiptTypes = receiptTypes
                return .none
            case .loadReceiptTypesResponse(.failure):
                state.isRegisteredReceiptTypesLoading = false
                state.isRegisteredReceiptTypesLoadSuccess = false
                state.registeredReceiptTypes = []
                state.isRegisteredReceiptTypesLoadError = true
                return .none
            case .loadDetail:
                if state.id.hasPrefix("custom_"), state.book != nil {
                    state.isLoading = false
                    return .none
                }
                state.isLoading = true
                state.errorMessage = nil
                return .run { [id = state.id] send in
                    let result = try await bookService.detail(id)
                    await send(.detailResponse(result))
                }
                .cancellable(id: CancelID.fetch, cancelInFlight: true)
            case .detailResponse(.success(let book)):
                state.isLoading = false
                state.errorMessage = nil
                state.book = book
                return .none
            case .checkAlreadyRegistered:
                return .run { [externalId = state.id] send in
                    let result = try await myBookService.isAlreadyRegistered(externalId)
                    await send(.alreadyRegisteredResponse(result))
                }
                .cancellable(id: CancelID.check, cancelInFlight: true)
            case .detailResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case .alreadyRegisteredResponse(.success(let exists)):
                state.isAlreadyRegistered = exists
                return .none
            case .alreadyRegisteredResponse(.failure(let error)):
                state.errorMessage = error.localizedDescription
                state.isAlreadyRegistered = nil
                return .none
            case .addButtonTapped(.mybooks(let externalId)):
                if let exists = state.isAlreadyRegistered {
                    if exists {
                        state.destination = .alert(.alreadyRegistered())
                        return .none
                    } else {
                        guard let book = state.book else {
                            return .none
                        }

                        state.destination = .formBook(BookFormFeature.State(externalId: externalId, externalBook: book, now: date.now))
                        return .none
                    }
                } else {
                    // Registration status unknown; do nothing or trigger re-check if desired
                    return .none
                }
            case .addButtonTapped(let receiptType):
                guard let book = state.book else {
                    return .none
                }

                let type: ReceiptType = receiptType == .purchase ? .purchase : .rental
                let isRegistered = state.registeredReceiptTypes.contains(where: { $0 == type })

                if isRegistered {
                    state.destination = .alert(.alreadyRegisteredReceipt(type: type))
                    return .none
                }

                if type == .purchase {
                    if state.book?.saleInfo?.saleability != "FOR_SALE" {
                        state.destination = .alert(.notRegisteredPrice())
                        return .none
                    }

                    state.isPurchasingSaving = true

                } else {
                    state.isRentalSaving = true
                }

                let userId = profile?.id.uuidString ?? ""
                return .run {
                    send in
                    let result = await localReceiptService.save(userId, book, type)
                    await send(.saveReceiptResponse(result))
                }
            case .saveReceiptResponse(let result):
                state.isRentalSaving = false
                state.isPurchasingSaving = false

                switch result {
                case .success(let receiptType):
                    state.registeredReceiptTypes.append(receiptType)
                    state.destination = .alert(.saveSuccessed(type: receiptType))

                    guard let book = state.book else {
                        return .none
                    }

                    let receiptBook = book.toReceiptBook(type: receiptType)
                    return .send(.delegate(.addBookToReceipt(receiptBook: receiptBook, type: receiptType)))

                case .failure:
                    state.destination = .alert(.saveFailed())
                    return .none
                }
            case .extendButtonTapped:
                state.isExtended.toggle()
                return .none
            case .destination(.presented(.addPrice(.delegate(.addBookToReceipt(let receiptBook))))):
                state.destination = nil
                state.registeredReceiptTypes.append(.purchase)
                return .send(.delegate(.addBookToReceipt(receiptBook: receiptBook, type: .purchase)))
            case .destination(.presented(.alert(.addPrice))):
                guard let book = state.book else {
                    return .none
                }

                state.destination = .addPrice(AddPriceFeature.State(externalBook: book))
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

extension ExternalBookDetailFeature {
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case formBook(BookFormFeature)
        case addPrice(AddPriceFeature)
        case alert(AlertState<ExternalBookDetailFeature.Action.Alert>)
    }
}

extension AlertState where Action == ExternalBookDetailFeature.Action.Alert {
    static func receiptConfirmation() -> Self {
        Self {
            TextState("added_to_receipt")
        } actions: {}
    }

    static func rentalConfirmation() -> Self {
        Self {
            TextState("added_to_rental")
        } actions: {}
    }

    static func saveSuccessed(type: ReceiptType) -> Self {
        Self {
            TextState(type == .rental ? String(localized: "added_to_rental") : String(localized: "added_to_purchase"))
        }
    }

    static func saveFailed() -> Self {
        Self {
            TextState("add_failed_retry")
        }
    }

    static func alreadyRegistered() -> Self {
        Self {
            TextState("book_already_registered")
        } actions: {}
    }

    static func alreadyRegisteredReceipt(type: ReceiptType) -> Self {
        Self {
            TextState(type == .rental ? String(localized: "already_in_rental") : String(localized: "already_in_purchase"))
        }
    }

    static func notRegisteredPrice() -> Self {
        Self {
            TextState("price_not_set_confirm")
        } actions: {
            ButtonState(action: .addPrice) {
                TextState("confirm")
            }
            ButtonState(role: .cancel) {
                TextState("cancel")
            }
        }
    }
}
