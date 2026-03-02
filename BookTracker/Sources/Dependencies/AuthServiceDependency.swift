//
//  AuthServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//

import ComposableArchitecture
import Supabase

private enum AuthServiceKey: DependencyKey {
    static let liveValue: AuthService = .live(client: SupabaseFactory.make())

    static let testValue: AuthService = .init(
        signUp: { _, _ in throw Unimplemented("unimplemented") },
        signIn: { _, _ in throw Unimplemented("unimplemented") },
        appleSignIn: { _, _ in throw Unimplemented("unimplemented") },
        signOut: {},
        currentSession: { nil },
        authStateChanges: { AsyncStream { $0.finish() } }
    )
}

extension DependencyValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}
