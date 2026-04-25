//
//  LocaleServiceDependency.swift
//  BookTracker
//
//  Created by 배성연 on 4/21/26.
//

import ComposableArchitecture

private enum LocaleServiceKey: DependencyKey {
    static let liveValue: LocaleService = .live()
    static let previewValue: LocaleService = .live()
    static let testValue: LocaleService = .init(
        currentLanguageCode: { "ko" },
        currencyForLocale: { .krw }
    )
}

extension DependencyValues {
    var localeService: LocaleService {
        get { self[LocaleServiceKey.self] }
        set { self[LocaleServiceKey.self] = newValue }
    }
}
