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
}

extension DependencyValues {
    var myInfoService: MyInfoService {
        get { self[MyInfoServiceKey.self] }
        set { self[MyInfoServiceKey.self] = newValue }
    }
}
