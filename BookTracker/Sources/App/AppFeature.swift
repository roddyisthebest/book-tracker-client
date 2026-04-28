//
//  AppFeature.swift
//  BookTracker
//
//  Created by 배성연 on 2/3/26.
//

import CasePaths
import ComposableArchitecture
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
                        state = .main(MainFeature.State())
                    } else if session == nil {
                        state = .auth(AuthFeature.State())
                    }
                    return .none

                case .signedIn, .tokenRefreshed, .userUpdated:
                    if session != nil {
                        state = .main(MainFeature.State())
                    }
                    return .none

                case .signedOut:
                    state = .auth(AuthFeature.State())
                    return .none

                case .passwordRecovery, .userDeleted, .mfaChallengeVerified:
                    return .none
                }

            case .main(.setting(.delegate(.deleteAccount))):
                state = .signingOut
                return .run { [authService, searchHistory, localReceiptService] send in
                    try? await searchHistory.clearAll()
                    _ = await localReceiptService.clearAll()
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
