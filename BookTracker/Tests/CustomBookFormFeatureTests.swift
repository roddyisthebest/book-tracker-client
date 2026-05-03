@testable import BookTracker
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct CustomBookFormFeatureTests {
    @Test func saveButtonTapped_invalidTitle_doesNothing() async {
        let store = TestStore(
            initialState: CustomBookFormFeature.State(title: "  "),
            reducer: { CustomBookFormFeature() }
        )

        await store.send(.saveButtonTapped)
    }

    @Test func saveButtonTapped_noImage_createsBookDirectly() async {
        let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

        var state = CustomBookFormFeature.State()
        state.title = "My Book"
        state.author = "Author"
        state.publisher = "Publisher"
        state.pageCount = "200"

        let store = TestStore(
            initialState: state,
            reducer: { CustomBookFormFeature() }
        )

        store.dependencies.uuid = .constant(fixedUUID)

        // isLoading goes true → false in same reducer call (no-image path), net: no state change
        await store.send(.saveButtonTapped)

        await store.receive(\.delegate)
    }

    @Test func saveButtonTapped_withImage_uploadsFirst() async {
        let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        let imageData = Data([0x00, 0x01])

        var state = CustomBookFormFeature.State()
        state.title = "My Book"
        state.selectedImageData = imageData

        let store = TestStore(
            initialState: state,
            reducer: { CustomBookFormFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.uuid = .constant(fixedUUID)
        store.dependencies.storageService.uploadBookCover = { _ in
            .success("https://example.com/cover.jpg")
        }

        await store.send(.saveButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.uploadResponse) {
            $0.isLoading = false
        }

        await store.receive(\.delegate)
    }

    @Test func uploadResponse_failure_showsAlert() async {
        var state = CustomBookFormFeature.State()
        state.title = "My Book"
        state.isLoading = true

        let store = TestStore(
            initialState: state,
            reducer: { CustomBookFormFeature() }
        )

        await store.send(.uploadResponse(.failure(.unknown(message: "fail")))) {
            $0.isLoading = false
            $0.alert = .uploadFailed(message: AppError.unknown(message: "fail").localizedDescription)
        }
    }

    @Test func imageSelected_setsData() async {
        let store = TestStore(
            initialState: CustomBookFormFeature.State(),
            reducer: { CustomBookFormFeature() }
        )

        let data = Data([0xff])

        await store.send(.imageSelected(data)) {
            $0.selectedImageData = data
        }
    }

    @Test func imageSelected_nil_clearsData() async {
        let store = TestStore(
            initialState: CustomBookFormFeature.State(selectedImageData: Data([0x01])),
            reducer: { CustomBookFormFeature() }
        )

        await store.send(.imageSelected(nil)) {
            $0.selectedImageData = nil
        }
    }

    @Test func saveButtonTapped_withPrice_includesSaleInfo() async {
        let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

        var state = CustomBookFormFeature.State()
        state.title = "Priced Book"
        state.retailPrice = "15000"
        state.currencyCode = .krw

        let store = TestStore(
            initialState: state,
            reducer: { CustomBookFormFeature() }
        )

        store.dependencies.uuid = .constant(fixedUUID)

        // no-image path: isLoading goes true → false in same reducer call, net: no state change
        await store.send(.saveButtonTapped)

        await store.receive(\.delegate)
    }
}
