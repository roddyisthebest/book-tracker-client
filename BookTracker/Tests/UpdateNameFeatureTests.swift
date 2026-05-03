@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct UpdateNameFeatureTests {
    @Test func updateSuccess_updatesProfileAndDelegates() async {
        let updatedProfile = TestFixtures.updatedProfile

        let store = TestStore(
            initialState: UpdateNameFeature.State(name: "Updated Name"),
            reducer: { UpdateNameFeature() }
        )

        store.dependencies.myInfoService.updateName = { _ in .success(updatedProfile) }

        await store.send(.updateButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.updateResponse) {
            $0.isLoading = false
            $0.$profile.withLock { $0 = updatedProfile }
        }

        await store.receive(\.delegate)
    }

    @Test func updateFailure_showsAlert() async {
        let store = TestStore(
            initialState: UpdateNameFeature.State(name: "New Name"),
            reducer: { UpdateNameFeature() }
        )

        store.dependencies.myInfoService.updateName = { _ in
            .failure(.unknown(message: "server error"))
        }

        await store.send(.updateButtonTapped) {
            $0.isLoading = true
        }

        await store.receive(\.updateResponse) {
            $0.isLoading = false
            $0.alert = .showUpdateErrorAlert()
        }
    }

    @Test func isSubmittable_emptyNameReturnsFalse() {
        let state = UpdateNameFeature.State(name: "")
        #expect(state.isSubmittable == false)
    }

    @Test func isSubmittable_sameNameReturnsFalse() {
        let state = UpdateNameFeature.State(name: "Original")
        // name == initialName, so not submittable
        #expect(state.isSubmittable == false)
    }

    @Test func isSubmittable_differentNameReturnsTrue() {
        var state = UpdateNameFeature.State(name: "Original")
        state.name = "Changed"
        #expect(state.isSubmittable == true)
    }
}
