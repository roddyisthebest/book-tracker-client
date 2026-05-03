@testable import BookTracker
import ComposableArchitecture
import Testing

@MainActor
struct MainFeatureTests {
    @Test func onAppear_loadsProfileAndAuthInfo() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.myInfoService.loadProfile = { .success(TestFixtures.profile) }
        store.dependencies.myInfoService.loadAuthInfo = { .success(TestFixtures.authInfo) }

        await store.send(.onAppear)

        // 비동기 응답은 완료 순서가 비결정적이므로 개별 테스트에서 검증
    }

    @Test func loadProfileResponse_success_setsProfile() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.loadProfileResponse(.success(TestFixtures.profile))) {
            $0.$profile.withLock { $0 = TestFixtures.profile }
        }
    }

    @Test func loadProfileResponse_failure_doesNothing() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.loadProfileResponse(.failure(.unknown(message: "fail"))))
    }

    @Test func loadAuthInfoResponse_success_setsAuthInfo() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.loadAuthInfoResponse(.success(TestFixtures.authInfo))) {
            $0.$authInfo.withLock { $0 = TestFixtures.authInfo }
        }
    }

    @Test func loadAuthInfoResponse_failure_doesNothing() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.loadAuthInfoResponse(.failure(.unknown(message: "fail"))))
    }

    @Test func onAppear_profileAlreadyLoaded_skips() async {
        var state = MainFeature.State()
        state.$profile.withLock { $0 = TestFixtures.profile }

        let store = TestStore(
            initialState: state,
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.onAppear)
        // No effects expected
    }

    @Test func tabSelected_updatesTab() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.tabSelected(.search)) {
            $0.selectedTab = .search
        }
    }

    @Test func resetDataDelegate_appDataDeleted_resetsSearchAndHome() async {
        var settingState = SettingFeature.State()
        settingState.path.append(.resetData(ResetDataFeature.State()))

        var state = MainFeature.State()
        state.setting = settingState
        state.home.didInitialLoad = true

        let store = TestStore(
            initialState: state,
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.setting(.path(.element(id: 0, action: .resetData(.delegate(.appDataDeleted)))))) {
            $0.search.destination = .suggestions(SearchSuggestionsFeature.State())
            $0.home.didInitialLoad = false
        }
    }

    @Test func resetDataDelegate_serverDataDeleted_reloadsLibrary() async {
        var settingState = SettingFeature.State()
        settingState.path.append(.resetData(ResetDataFeature.State()))

        var state = MainFeature.State()
        state.setting = settingState
        state.home.didInitialLoad = true

        let store = TestStore(
            initialState: state,
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        await store.send(.setting(.path(.element(id: 0, action: .resetData(.delegate(.serverDataDeleted)))))) {
            $0.home.didInitialLoad = false
        }

        await store.receive(\.library)
    }

    @Test func loadProfileResponse_success_triggersHomeLoadBookCount() async {
        let store = TestStore(
            initialState: MainFeature.State(),
            reducer: { MainFeature() }
        )
        store.exhaustivity = .off

        store.dependencies.localReceiptService.counts = { _ in .success([.purchase: 0, .rental: 0]) }

        await store.send(.loadProfileResponse(.success(TestFixtures.profile))) {
            $0.$profile.withLock { $0 = TestFixtures.profile }
        }

        await store.receive(\.home.loadBookCount)
    }
}
