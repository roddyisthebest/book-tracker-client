//
//  SharedKeys.swift
//  BookTracker
//

import Sharing

extension SharedReaderKey where Self == InMemoryKey<MyProfile?> {
    static var userProfile: Self { .inMemory("userProfile") }
}

extension SharedReaderKey where Self == InMemoryKey<MyAuthInfo?> {
    static var userAuthInfo: Self { .inMemory("userAuthInfo") }
}
