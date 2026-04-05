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
        case .krw: return "대한민국 원"
        case .usd: return "미국 달러"
        case .jpy: return "일본 엔"
        case .eur: return "유로"
        case .cny: return "중국 위안"
        case .gbp: return "영국 파운드"
        case .aud: return "호주 달러"
        case .cad: return "캐나다 달러"
        case .hkd: return "홍콩 달러"
        case .sgd: return "싱가포르 달러"
        }
    }
}
