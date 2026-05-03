//
//  CustomBookFormFeature.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct CustomBookFormFeature {
    @Dependency(\.storageService) var storageService
    @Dependency(\.uuid) var uuid

    @ObservableState
    struct State: Equatable {
        var title: String = ""
        var author: String = ""
        var publisher: String = ""
        var pageCount: String = ""
        var isbn: String = ""
        var description: String = ""

        var selectedImageData: Data? = nil
        var retailPrice: String = ""
        var currencyCode: CurrencyCode = .krw

        var isLoading: Bool = false

        var isValid: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        @Presents var alert: AlertState<CustomBookFormFeature.Action.Alert>?
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case uploadResponse(Result<String, AppError>)
        case imageSelected(Data?)

        case alert(PresentationAction<Alert>)
        enum Alert: Equatable {}

        case delegate(Delegate)
        enum Delegate: Equatable {
            case didCreate(ExternalBook)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .saveButtonTapped:
                guard state.isValid else { return .none }
                state.isLoading = true

                if let imageData = state.selectedImageData {
                    return .run { send in
                        let result = await storageService.uploadBookCover(imageData)
                        await send(.uploadResponse(result))
                    }
                } else {
                    let book = buildExternalBook(from: state, thumbnailURL: nil)
                    state.isLoading = false
                    return .send(.delegate(.didCreate(book)))
                }

            case .uploadResponse(.success(let urlString)):
                let thumbnailURL = URL(string: urlString)
                let book = buildExternalBook(from: state, thumbnailURL: thumbnailURL)
                state.isLoading = false
                return .send(.delegate(.didCreate(book)))

            case .uploadResponse(.failure(let error)):
                state.isLoading = false
                print(error, "error")
                state.alert = .uploadFailed(message: error.localizedDescription)
                return .none

            case .imageSelected(let data):
                state.selectedImageData = data
                return .none

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

    private func buildExternalBook(from state: State, thumbnailURL: URL?) -> ExternalBook {
        let id = "custom_\(uuid())"
        let trimmedTitle = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let authors: [String]? = state.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : [state.author.trimmingCharacters(in: .whitespacesAndNewlines)]
        let publisher: String? = state.publisher.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : state.publisher.trimmingCharacters(in: .whitespacesAndNewlines)
        let pageCount = Int(state.pageCount) ?? 100
        let isbn13: String? = state.isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : state.isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        let description: String? = state.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : state.description.trimmingCharacters(in: .whitespacesAndNewlines)

        var saleInfo: ExternalBook.SaleInfo? = nil
        if let priceValue = Double(state.retailPrice), priceValue > 0 {
            let money = ExternalBook.SaleInfo.Money(amount: priceValue, currencyCode: state.currencyCode.rawValue)
            let amountInMicros = Int64(priceValue) * CurrencyCode.microsPerUnit
            let moneyMicros = ExternalBook.SaleInfo.MoneyMicros(amountInMicros: amountInMicros, currencyCode: state.currencyCode.rawValue)
            saleInfo = ExternalBook.SaleInfo(
                saleability: "FOR_SALE",
                retailPrice: money,
                offers: [
                    ExternalBook.SaleInfo.Offer(
                        finskyOfferType: 1,
                        listPrice: moneyMicros,
                        retailPrice: moneyMicros
                    )
                ]
            )
        }

        return ExternalBook(
            id: id,
            title: trimmedTitle,
            authors: authors,
            publisher: publisher,
            description: description,
            pageCount: pageCount,
            thumbnail: thumbnailURL,
            isbn13: isbn13,
            saleInfo: saleInfo
        )
    }
}

extension AlertState where Action == CustomBookFormFeature.Action.Alert {
    static func uploadFailed(message: String) -> Self {
        Self {
            TextState(message)
        }
    }
}
