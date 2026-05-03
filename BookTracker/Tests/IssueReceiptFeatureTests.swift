@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct IssueReceiptFeatureTests {
    @Test func issueButtonTapped_setsLoadingAndCreates() async {
        let fixedId = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

        let store = TestStore(
            initialState: IssueReceiptFeature.State(
                receiptBooks: [TestFixtures.receiptBook],
                type: .purchase,
                source: "google_books",
                receiptAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            reducer: { IssueReceiptFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.receiptService.createReceiptWithBooks = { _, _, _, _, _, _ in .success(fixedId) }

        await store.send(.issueButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.createResponse) {
            $0.isLoading = false
        }
    }

    @Test func createResponse_success_showsAlert() async {
        let store = TestStore(
            initialState: IssueReceiptFeature.State(
                receiptBooks: [TestFixtures.receiptBook],
                type: .purchase
            ),
            reducer: { IssueReceiptFeature() }
        )

        let fixedId = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

        await store.send(.createResponse(.success(fixedId))) {
            $0.isLoading = false
            $0.alert = .showCreationSuccessAlert()
        }
    }

    @Test func createResponse_failure_showsAlert() async {
        let store = TestStore(
            initialState: IssueReceiptFeature.State(
                receiptBooks: [TestFixtures.receiptBook],
                type: .purchase
            ),
            reducer: { IssueReceiptFeature() }
        )

        await store.send(.createResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoading = false
            $0.alert = .showCreationErrorAlert()
        }
    }

    @Test func confirmCreation_removesLocalAndDelegates() async {
        var state = IssueReceiptFeature.State(
            receiptBooks: [TestFixtures.receiptBook],
            type: .purchase
        )
        state.alert = .showCreationSuccessAlert()

        let store = TestStore(
            initialState: state,
            reducer: { IssueReceiptFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.removeSpecificTypes = { _, _ in .success(true) }

        await store.send(.alert(.presented(.confirmCreation))) {
            $0.alert = nil
        }

        await store.receive(\.delegate)
    }
}
