//
//  AppFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import CasePaths
import ComposableArchitecture
import Sharing
import Supabase

@Reducer
struct AppFeature {
    @ObservableState
    @CasePathable
    enum State: Equatable {
        case auth(AuthFeature.State)
        case main(MainFeature.State)
        case launching
        case signingOut
    }

    @CasePathable
    enum Action {
        case onAppear
        case authStateChanged(AuthChangeEvent, Session?)
        case auth(AuthFeature.Action)
        case main(MainFeature.Action)
        case logout
        case login
    }

    @Dependency(\.authService) var authService
    @Dependency(\.searchHistory) var searchHistory
    @Dependency(\.localReceiptService) var localReceiptService
    @Dependency(\.localCustomBookService) var localCustomBookService
    @Shared(.userId) var userId: String?
    @Shared(.userProfile) var userProfile: MyProfile?
    @Shared(.userAuthInfo) var userAuthInfo: MyAuthInfo?
    private enum CancelID { case authChanges }

    var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) { AuthFeature() }
        Scope(state: \.main, action: \.main) { MainFeature() }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    for await (event, session) in authService.authStateChanges() {
                        await send(.authStateChanged(event, session))
                    }
                }
                .cancellable(id: CancelID.authChanges, cancelInFlight: true)

            case let .authStateChanged(event, session):
                switch event {
                case .initialSession:
                    // If a valid, non-expired session exists, go to main; if none, go to auth.
                    if let s = session, !s.isExpired {
                        $userId.withLock { $0 = s.user.id.uuidString }
                        state = .main(MainFeature.State())
                    } else if session == nil {
                        state = .auth(AuthFeature.State())
                    }
                    return .none

                case .signedIn, .tokenRefreshed, .userUpdated:
                    if let s = session {
                        $userId.withLock { $0 = s.user.id.uuidString }
                        state = .main(MainFeature.State())
                    }
                    return .none

                case .signedOut:
                    $userId.withLock { $0 = nil }
                    $userProfile.withLock { $0 = nil }
                    $userAuthInfo.withLock { $0 = nil }
                    state = .auth(AuthFeature.State())
                    return .none

                case .passwordRecovery, .userDeleted, .mfaChallengeVerified:
                    return .none
                }

            case .main(.setting(.delegate(.deleteAccount))):
                let userId = userId ?? ""
                state = .signingOut
                return .run { [authService, searchHistory, localReceiptService, localCustomBookService] send in
                    try? await searchHistory.clearAll(userId)
                    _ = await localReceiptService.clearAll(userId)
                    _ = await localCustomBookService.clearAll(userId)
                    try? await authService.signOut()
                    await send(.logout)
                }

            case .main(.setting(.delegate(.logout))):
                // Show a dedicated signing-out state while performing logout.
                state = .signingOut
                return .run { _ in
                    try await authService.signOut()

                } catch: { error, send in
                    if error is CancellationError { return }
                    // Even if signOut fails over the network, route to auth to keep UX consistent.
                    await send(.logout)
                }

            case .login:
                state = .main(MainFeature.State())
                return .none

            case .logout:
                $userId.withLock { $0 = nil }
                $userProfile.withLock { $0 = nil }
                $userAuthInfo.withLock { $0 = nil }
                state = .auth(AuthFeature.State())
                return .none

            case .auth:
                return .none

            case .main:
                return .none
            }
        }
    }
}
