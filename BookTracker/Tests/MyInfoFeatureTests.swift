@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct MyInfoFeatureTests {
    @Test func nameEditButtonTapped_presentsUpdateName() async {
        var state = MyInfoFeature.State()
        state.$profile.withLock { $0 = TestFixtures.profile }

        let store = TestStore(
            initialState: state,
            reducer: { MyInfoFeature() }
        )
        store.exhaustivity = .off

        await store.send(.nameEditButtonTapped) {
            $0.destination = .updateName(UpdateNameFeature.State(name: "Test User"))
        }
    }

    @Test func nameEditButtonTapped_nilProfile_usesEmpty() async {
        let store = TestStore(
            initialState: MyInfoFeature.State(),
            reducer: { MyInfoFeature() }
        )
        store.exhaustivity = .off

        await store.send(.nameEditButtonTapped) {
            $0.destination = .updateName(UpdateNameFeature.State(name: ""))
        }
    }

    @Test func profileImageViewTapped_updatesImage() async {
        let store = TestStore(
            initialState: MyInfoFeature.State(),
            reducer: { MyInfoFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.myInfoService.updateImageUuid = { _ in .success(TestFixtures.updatedProfile) }

        await store.send(.profileImageViewTapped) {
            $0.isUpdatingImage = true
        }

        await store.receive(\.updateImageUuidResponse) {
            $0.isUpdatingImage = false
        }
    }

    @Test func profileImageViewTapped_failure_stopsLoading() async {
        let store = TestStore(
            initialState: MyInfoFeature.State(),
            reducer: { MyInfoFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.myInfoService.updateImageUuid = { _ in .failure(.unknown(message: "fail")) }

        await store.send(.profileImageViewTapped) {
            $0.isUpdatingImage = true
        }

        await store.receive(\.updateImageUuidResponse) {
            $0.isUpdatingImage = false
        }
    }

    @Test func profileImageViewTapped_guardWhileUpdating() async {
        var state = MyInfoFeature.State()
        state.isUpdatingImage = true

        let store = TestStore(
            initialState: state,
            reducer: { MyInfoFeature() }
        )

        await store.send(.profileImageViewTapped)
    }

    @Test func updateNameDelegate_dismissesDestination() async {
        var state = MyInfoFeature.State()
        state.destination = .updateName(UpdateNameFeature.State(name: "Test"))

        let store = TestStore(
            initialState: state,
            reducer: { MyInfoFeature() }
        )
        store.exhaustivity = .off

        await store.send(.destination(.presented(.updateName(.delegate(.didUpdate))))) {
            $0.destination = nil
        }
    }
}
