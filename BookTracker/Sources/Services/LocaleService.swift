//
//  LocaleService.swift
//  BookTracker
//
//  Created by 배성연 on 4/21/26.
//

import Foundation

struct LocaleService {
    var currentLanguageCode: () -> String
    var currencyForLocale: () -> CurrencyCode
}

extension LocaleService {
    static func live() -> Self {
        Self(
            currentLanguageCode: {
                Locale.current.language.languageCode?.identifier ?? "en"
            },
            currencyForLocale: {
                let lang = Locale.current.language.languageCode?.identifier ?? ""
                switch lang {
                case "ko": return .krw
                case "ja": return .jpy
                default:   return .usd
                }
            }
        )
    }
}
