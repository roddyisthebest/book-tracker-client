//
//  AppleAuthClientDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/2/26.
//

import ComposableArchitecture

private enum AppleAuthClientKey: DependencyKey {
    static let liveValue: AppleAuthClient = .live
    static let testValue: AppleAuthClient = .init(signIn: { throw AppleAuthError.missingIdentityToken })
}

extension DependencyValues {
    var appleAuthClient: AppleAuthClient {
        get { self[AppleAuthClientKey.self] }
        set { self[AppleAuthClientKey.self] = newValue }
    }
}
