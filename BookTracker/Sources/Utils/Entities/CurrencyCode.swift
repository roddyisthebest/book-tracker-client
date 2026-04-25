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

    var symbolName: String {
        switch self {
        case .krw: return "wonsign"
        case .usd, .aud, .cad, .hkd, .sgd: return "dollarsign"
        case .jpy, .cny: return "yensign"
        case .eur: return "eurosign"
        case .gbp: return "sterlingsign"
        }
    }

    var ratePerUSD: Double {
        switch self {
        case .krw: return 1350.0
        case .usd: return 1.0
        case .jpy: return 150.0
        case .eur: return 0.92
        case .cny: return 7.25
        case .gbp: return 0.79
        case .aud: return 1.55
        case .cad: return 1.37
        case .hkd: return 7.82
        case .sgd: return 1.35
        }
    }

    static func convertMicros(_ amountInMicros: Int64, from source: CurrencyCode, to target: CurrencyCode) -> Int64 {
        guard source != target else { return amountInMicros }
        let usdAmount = Double(amountInMicros) / source.ratePerUSD
        let targetAmount = usdAmount * target.ratePerUSD
        return Int64(targetAmount.rounded())
    }

    static let microsPerUnit: Int64 = 1_000_000

    static func baseUnits(fromMicros micros: Int64) -> Int {
        Int(micros / microsPerUnit)
    }

    static func formattedPriceMicros(amountInMicros: Int64, currencyCode: String?) -> String {
        formattedPrice(amount: baseUnits(fromMicros: amountInMicros), currencyCode: currencyCode)
    }

    static func formattedPrice(amount: Int, currencyCode: String?) -> String {
        let code = (currencyCode?.uppercased()) ?? "KRW"
        if code == "KRW" || code == "WON" {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            formatter.maximumFractionDigits = 0
            let value = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
            return "\(value)" + String(localized: "won_unit")
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            let value = formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(code)"
            return value
        }
    }
}
