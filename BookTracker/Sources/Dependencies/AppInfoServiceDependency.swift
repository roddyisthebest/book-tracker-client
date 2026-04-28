//
//  AppInfoServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 4/28/26.
//

import ComposableArchitecture

private enum AppInfoServiceKey: DependencyKey {
    static let liveValue: AppInfoService = .live()
    static let previewValue: AppInfoService = .live()
    static let testValue: AppInfoService = .init(
        appVersion: { "1.0.0" },
        buildNumber: { "1" },
        versionDisplay: { "v 1.0.0 (1)" }
    )
}

extension DependencyValues {
    var appInfoService: AppInfoService {
        get { self[AppInfoServiceKey.self] }
        set { self[AppInfoServiceKey.self] = newValue }
    }
}
