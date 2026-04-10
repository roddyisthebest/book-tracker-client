//
//  CurrencyCode.swift
//  BookTracker
//
//  Created by 배성연 on 3/29/26.
//

import Foundation

enum CurrencyCode: String, CaseIterable, Equatable, Hashable, Codable {
    case krw = "KRW"
    case usd = "USD"
    case jpy = "JPY"
    case eur = "EUR"
    case cny = "CNY"
    case gbp = "GBP"
    case aud = "AUD"
    case cad = "CAD"
    case hkd = "HKD"
    case sgd = "SGD"

    var description: String {
        switch self {
        case .krw: return String(localized: "currency_krw")
        case .usd: return String(localized: "currency_usd")
        case .jpy: return String(localized: "currency_jpy")
        case .eur: return String(localized: "currency_eur")
        case .cny: return String(localized: "currency_cny")
        case .gbp: return String(localized: "currency_gbp")
        case .aud: return String(localized: "currency_aud")
        case .cad: return String(localized: "currency_cad")
        case .hkd: return String(localized: "currency_hkd")
        case .sgd: return String(localized: "currency_sgd")
        }
    }
}
