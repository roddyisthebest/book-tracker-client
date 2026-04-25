//
//  ReceiptBook.swift
//  BookTracker
//
//  Created by 배성연 on 2/5/26.
//

import Foundation

enum ReceiptType: String, Equatable, Hashable, Codable {
    case purchase
    case rental

    var title: String {
        switch self {
        case .purchase: return String(localized: "purchase_receipt")
        case .rental: return String(localized: "rental_receipt")
        }
    }
}

struct Receipt: Equatable, Identifiable {
    let id: UUID
    let type: ReceiptType
    let title: String
}

struct ReceiptSaleInfo: Codable, Equatable {
    let amountInMicros: Int64?
    let currencyCode: CurrencyCode?

    var priceText: String? {
        guard let amountInMicros else { return nil }
        return CurrencyCode.formattedPriceMicros(amountInMicros: amountInMicros, currencyCode: currencyCode?.rawValue)
    }
}

struct ReceiptBook: Codable, Equatable, Identifiable {
    let id: String // externalBookId
    let type: ReceiptType

    let title: String
    let authors: [String]
    let publisher: String?
    let pageCount: Int?
    let thumbnailURL: String?
    let isbn13: String?
    let saleInfo: ReceiptSaleInfo?
}

extension ReceiptBook {
    init(externalBook: ExternalBook, type: ReceiptType) {
        self.id = externalBook.id
        self.type = type
        self.title = externalBook.title
        self.authors = externalBook.authors ?? []
        self.publisher = externalBook.publisher
        self.pageCount = externalBook.pageCount
        self.thumbnailURL = externalBook.thumbnail?.absoluteString
        self.isbn13 = externalBook.isbn13
        self.saleInfo = ReceiptSaleInfo(
            amountInMicros: externalBook.saleInfo?.offers?.first?.retailPrice?.amountInMicros,
            currencyCode: externalBook.saleInfo?.offers?.first?.retailPrice?.currencyCode.flatMap { CurrencyCode(rawValue: $0) }
        )
    }
}

extension ReceiptBook {
    init(externalBook: ExternalBook, type: ReceiptType, amountInMicros: Int64, currencyCode: CurrencyCode) {
        self.id = externalBook.id
        self.type = type
        self.title = externalBook.title
        self.authors = externalBook.authors ?? []
        self.publisher = externalBook.publisher
        self.pageCount = externalBook.pageCount
        self.thumbnailURL = externalBook.thumbnail?.absoluteString
        self.isbn13 = externalBook.isbn13
        self.saleInfo = ReceiptSaleInfo(
            amountInMicros: amountInMicros,
            currencyCode: currencyCode
        )
    }
}

extension ReceiptBook {
    var authorText: String? {
        authors.first
    }

    var thumbnail: URL? {
        guard let thumbnailURL else { return nil }
        return URL(string: thumbnailURL)
    }
}

extension ReceiptBook {
    func toBook(
        memo: String
    ) -> Book {
        Book(
            id: UUID(),
            userId: UUID(),
            externalBookId: id,
            title: title,
            author: authorText ?? "",
            publisher: publisher ?? "",
            pageCount: pageCount,
            pageCountEditable: pageCount != nil,
            imageUrl: thumbnailURL ?? "",
            isbn: isbn13 ?? "",
            status: .want,
            type: .paper,
            startedAt: nil,
            readCount: nil,
            memo: memo,
            endedAt: nil,
            score: nil,
            review: nil,
            droppedReason: nil
        )
    }
}

extension ReceiptBook {
    func toReceiptRpcItem() -> ReceiptRpcItem {
        let sourceCurrency = saleInfo?.currencyCode ?? .krw
        let micros = saleInfo?.amountInMicros ?? 0
        let usdMicros = CurrencyCode.convertMicros(micros, from: sourceCurrency, to: .usd)

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let exchangeRateDate = dateFormatter.string(from: Date())

        return ReceiptRpcItem(
            externalBookId: id,
            title: title,
            author: authorText,
            publisher: publisher,
            pageCount: pageCount,
            imageUrl: thumbnailURL,
            isbn: isbn13,
            quantity: 1,
            micros: micros,
            currencyCode: sourceCurrency,
            usdMicros: usdMicros,
            exchangeRateToUsd: sourceCurrency.ratePerUSD,
            exchangeRateDate: exchangeRateDate
        )
    }
}

extension ReceiptBook {
    static func sample() -> ReceiptBook {
        ReceiptBook(id: "test", type: .purchase, title: "", authors: ["안녕"], publisher: "ㅁㄴㅇㄴ", pageCount: 123, thumbnailURL: "https://imgnews.pstatic.net/image/311/2026/03/28/0001991458_001_20260328191013567.jpg?type=w647", isbn13: "fdgasfasdfasdfadf", saleInfo: ReceiptSaleInfo(amountInMicros: 120_303_000_000, currencyCode: .krw))
    }
}
