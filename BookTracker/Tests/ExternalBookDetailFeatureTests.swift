@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ExternalBookDetailFeatureTests {
    @Test func onAppear_loadsDetailAndReceiptTypes() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(id: "ext-001"),
            reducer: { ExternalBookDetailFeature() }
        )

        store.dependencies.externalBookService.detail = { _ in .success(TestFixtures.externalBook) }
        store.dependencies.bookService.isAlreadyRegistered = { _ in .success(false) }
        store.dependencies.localReceiptService.registeredTypes = { _, _ in .success([]) }
        store.exhaustivity = .off

        await store.send(.onAppear)

        // 동기 send 3개 수신 확인
        await store.receive(\.loadDetail) {
            $0.isLoading = true
        }
        await store.receive(\.loadReceiptTypes) {
            $0.receiptTypesLoadState = .loading
        }
        await store.receive(\.checkAlreadyRegistered)

        // 비동기 응답 3개는 완료 순서가 비결정적이므로 개별 receive하지 않음
        // 각 응답의 동작은 개별 테스트(detailResponse_failure_setsError 등)에서 검증
    }

    @Test func addButtonTapped_mybooks_alreadyRegistered_showsAlert() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: TestFixtures.externalBook,
                isAlreadyRegistered: true
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.addButtonTapped(.mybooks(externalId: "ext-001"))) {
            $0.destination = .alert(.alreadyRegistered())
        }
    }

    @Test func addButtonTapped_mybooks_notRegistered_showsForm() async {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: TestFixtures.externalBook,
                isAlreadyRegistered: false
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        store.dependencies.date = .constant(fixedDate)

        await store.send(.addButtonTapped(.mybooks(externalId: "ext-001"))) {
            $0.destination = .formBook(
                BookFormFeature.State(externalId: "ext-001", externalBook: TestFixtures.externalBook, now: fixedDate)
            )
        }
    }

    @Test func addButtonTapped_rental_savesAndDelegates() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: TestFixtures.externalBook,
                registeredReceiptTypes: []
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        store.dependencies.localReceiptService.save = { _, _, type in .success(type) }

        await store.send(.addButtonTapped(.rental)) {
            $0.isRentalSaving = true
        }

        await store.receive(\.saveReceiptResponse) {
            $0.isRentalSaving = false
            $0.isPurchasingSaving = false
            $0.registeredReceiptTypes = [.rental]
            $0.destination = .alert(.saveSuccessed(type: .rental))
        }

        await store.receive(\.delegate)
    }

    @Test func addButtonTapped_purchase_alreadyInReceipt_showsAlert() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: TestFixtures.externalBook,
                registeredReceiptTypes: [.purchase]
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.addButtonTapped(.purchase)) {
            $0.destination = .alert(.alreadyRegisteredReceipt(type: .purchase))
        }
    }

    @Test func addButtonTapped_purchase_notForSale_showsPriceAlert() async {
        // ExternalBook without saleability = "FOR_SALE"
        let book = ExternalBook(id: "ext-001", title: "No Sale Book")

        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: book,
                registeredReceiptTypes: []
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.addButtonTapped(.purchase)) {
            $0.destination = .alert(.notRegisteredPrice())
        }
    }

    @Test func saveReceiptResponse_failure_showsAlert() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: TestFixtures.externalBook,
                isRentalSaving: true
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.saveReceiptResponse(.failure(.unknown))) {
            $0.isRentalSaving = false
            $0.isPurchasingSaving = false
            $0.destination = .alert(.saveFailed())
        }
    }

    @Test func detailResponse_failure_setsError() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(id: "ext-001"),
            reducer: { ExternalBookDetailFeature() }
        )

        store.dependencies.externalBookService.detail = { _ in
            .failure(.invalidURL)
        }

        await store.send(.loadDetail) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.detailResponse) {
            $0.isLoading = false
            $0.errorMessage = ExternalBookService.ServiceError.invalidURL.localizedDescription
        }
    }

    @Test func extendButtonTapped_togglesExtended() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(id: "ext-001"),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.extendButtonTapped) {
            $0.isExtended = true
        }

        await store.send(.extendButtonTapped) {
            $0.isExtended = false
        }
    }

    @Test func detailResponse_success_setsBook() async {
        var state = ExternalBookDetailFeature.State(id: "ext-001")
        state.isLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.detailResponse(.success(TestFixtures.externalBook))) {
            $0.isLoading = false
            $0.errorMessage = nil
            $0.book = TestFixtures.externalBook
        }
    }

    @Test func alreadyRegisteredResponse_success_setsFlag() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(id: "ext-001"),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.alreadyRegisteredResponse(.success(true))) {
            $0.isAlreadyRegistered = true
        }
    }

    @Test func alreadyRegisteredResponse_failure_setsErrorMessage() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(id: "ext-001"),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.alreadyRegisteredResponse(.failure(.unknown(message: "fail")))) {
            $0.errorMessage = AppError.unknown(message: "fail").localizedDescription
            $0.isAlreadyRegistered = nil
        }
    }

    @Test func loadReceiptTypesResponse_success_setsTypes() async {
        var state = ExternalBookDetailFeature.State(id: "ext-001")
        state.receiptTypesLoadState = .loading

        let store = TestStore(
            initialState: state,
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.loadReceiptTypesResponse(.success([.purchase, .rental]))) {
            $0.receiptTypesLoadState = .loaded
            $0.registeredReceiptTypes = [.purchase, .rental]
        }
    }

    @Test func loadReceiptTypesResponse_failure_setsError() async {
        var state = ExternalBookDetailFeature.State(id: "ext-001")
        state.receiptTypesLoadState = .loading

        let store = TestStore(
            initialState: state,
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.loadReceiptTypesResponse(.failure(.unknown))) {
            $0.receiptTypesLoadState = .error
            $0.registeredReceiptTypes = []
        }
    }

    @Test func addPriceAlert_presentsAddPriceDestination() async {
        let book = TestFixtures.externalBook

        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: book,
                destination: .alert(.notRegisteredPrice())
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.destination(.presented(.alert(.addPrice)))) {
            $0.destination = .addPrice(AddPriceFeature.State(externalBook: book))
        }
    }

    @Test func addButtonTapped_purchase_forSale_savesReceipt() async {
        let saleInfo = ExternalBook.SaleInfo(
            saleability: "FOR_SALE",
            retailPrice: ExternalBook.SaleInfo.Money(amount: 15000, currencyCode: "KRW"),
            offers: nil
        )
        let book = ExternalBook(
            id: "ext-001",
            title: "For Sale Book",
            saleInfo: saleInfo
        )

        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: book,
                registeredReceiptTypes: []
            ),
            reducer: { ExternalBookDetailFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.save = { _, _, type in .success(type) }

        await store.send(.addButtonTapped(.purchase)) {
            $0.isPurchasingSaving = true
        }

        await store.receive(\.saveReceiptResponse) {
            $0.isPurchasingSaving = false
            $0.isRentalSaving = false
            $0.registeredReceiptTypes = [.purchase]
        }

        await store.receive(\.delegate)
    }

    @Test func addButtonTapped_mybooks_unknownRegistration_doesNothing() async {
        let store = TestStore(
            initialState: ExternalBookDetailFeature.State(
                id: "ext-001",
                book: TestFixtures.externalBook,
                isAlreadyRegistered: nil
            ),
            reducer: { ExternalBookDetailFeature() }
        )

        await store.send(.addButtonTapped(.mybooks(externalId: "ext-001")))
    }
}
