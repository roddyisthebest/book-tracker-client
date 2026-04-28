//
//  SharedKeys.swift
//  BookTracker
//

import Sharing

extension SharedReaderKey where Self == InMemoryKey<MyProfile?> {
    static var userProfile: Self { .inMemory("userProfile") }
}
