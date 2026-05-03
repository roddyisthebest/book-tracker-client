//
//  MyInfoServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 3/24/26.
//

import Dependencies
import Supabase

private enum MyInfoServiceKey: DependencyKey {
    static let liveValue: MyInfoService = .live(client: SupabaseFactory.make())

    static let testValue: MyInfoService = .init(
        loadProfile: { .failure(.unknown(message: "unimplemented")) },
        loadAuthInfo: { .failure(.unknown(message: "unimplemented")) },
        updateName: { _ in .failure(.unknown(message: "unimplemented")) },
        updateImageUuid: { _ in .failure(.unknown(message: "unimplemented")) },
        deleteAllMyBookRelatedData: { .failure(.unknown(message: "unimplemented")) }
    )
}

extension DependencyValues {
    var myInfoService: MyInfoService {
        get { self[MyInfoServiceKey.self] }
        set { self[MyInfoServiceKey.self] = newValue }
    }
}
