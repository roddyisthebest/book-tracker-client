//
//  SharedKeys.swift
//  BookTracker
//

import Sharing

extension SharedReaderKey where Self == InMemoryKey<MyProfile?> {
    static var userProfile: Self { .inMemory("userProfile") }
}

extension SharedReaderKey where Self == InMemoryKey<String?> {
    static var userId: Self { .inMemory("userId") }
}

extension SharedReaderKey where Self == InMemoryKey<MyAuthInfo?> {
    static var userAuthInfo: Self { .inMemory("userAuthInfo") }
}
