//
//  ReceiptService.swift
//  BookTracker
//
//  Created by 배성연 on 3/28/26.
//

import Foundation
import Supabase

// MARK: - Create RPC Models

struct ReceiptRpcItem: Equatable, Codable, Hashable {
    let externalBookId: String
    let title: String?
    let author: String?
    let publisher: String?
    let pageCount: Int?
    let imageUrl: String?
    let isbn: String?
    let quantity: Int?
    let micros: Int64?
    let currencyCode: CurrencyCode?
    let usdMicros: Int64?
    let exchangeRateToUsd: Double?
    let exchangeRateDate: String?

    enum CodingKeys: String, CodingKey {
        case externalBookId = "external_book_id"
        case title
        case author
        case publisher
        case pageCount = "page_count"
        case imageUrl = "image_url"
        case isbn
        case quantity
        case micros
        case currencyCode = "currency_code"
        case usdMicros = "usd_micros"
        case exchangeRateToUsd = "exchange_rate_to_usd"
        case exchangeRateDate = "exchange_rate_date"
    }
}

private struct CreateReceiptWithBooksPayload: Encodable {
    let pSource: String
    let pTotalMicros: Int64?
    let pTotalUsdMicros: Int64?
    let pType: String
    let pReceiptAt: Date?
    let pItems: [ReceiptRpcItem]

    enum CodingKeys: String, CodingKey {
        case pSource = "p_source"
        case pTotalMicros = "p_total_micros"
        case pTotalUsdMicros = "p_total_usd_micros"
        case pType = "p_type"
        case pReceiptAt = "p_receipt_at"
        case pItems = "p_items"
    }
}

// MARK: - List Models

struct ReceiptSummary: Equatable, Codable, Hashable {
    let id: UUID
    let createdAt: Date?
    let receiptAt: Date?
    let source: String
    let totalMicros: Int64?
    let totalUsdMicros: Int64?
    let type: ReceiptType
    let firstBookTitle: String?
    let totalQuantity: Int
    let sourceCurrencyCode: CurrencyCode

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case receiptAt = "receipt_at"
        case source
        case totalMicros = "total_micros"
        case totalUsdMicros = "total_usd_micros"
        case type
        case firstBookTitle = "first_book_title"
        case totalQuantity = "total_quantity"
        case sourceCurrencyCode = "source_currency_code"
    }
}

private struct ReceiptSummaryDTO: Decodable {
    let id: UUID
    let createdAt: String?
    let receiptAt: String?
    let source: String
    let totalMicros: Int64?
    let totalUsdMicros: Int64?
    let type: String
    let firstBookTitle: String?
    let totalQuantity: Int
    let currencyCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case receiptAt = "receipt_at"
        case source
        case totalMicros = "total_micros"
        case totalUsdMicros = "total_usd_micros"
        case type
        case firstBookTitle = "first_book_title"
        case totalQuantity = "total_quantity"
        case currencyCode = "currency_code"
    }
}

private extension ReceiptSummaryDTO {
    func toDomain() -> ReceiptSummary {
        ReceiptSummary(
            id: id,
            createdAt: ReceiptDateParser.parse(createdAt),
            receiptAt: ReceiptDateParser.parse(receiptAt),
            source: source,
            totalMicros: totalMicros,
            totalUsdMicros: totalUsdMicros,
            type: ReceiptType(rawValue: type) ?? .purchase,
            firstBookTitle: firstBookTitle,
            totalQuantity: totalQuantity,
            sourceCurrencyCode: currencyCode.flatMap { CurrencyCode(rawValue: $0.uppercased()) } ?? .krw
        )
    }
}

enum ReceiptDateParser {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let withoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return withFractionalSeconds.date(from: value)
            ?? withoutFractionalSeconds.date(from: value)
    }
}

// MARK: - Detail Models

struct ReceiptDetail: Equatable, Hashable {
    let id: UUID
    let createdAt: Date?
    let receiptAt: Date?
    let source: String
    let totalMicros: Int64?
    let totalUsdMicros: Int64?
    let type: ReceiptType
    let items: [ReceiptDetailItem]

    var sourceCurrencyCode: CurrencyCode {
        for item in items {
            if let code = item.currencyCode,
               let currency = CurrencyCode(rawValue: code.uppercased())
            {
                return currency
            }
        }
        return .krw
    }

    func convertedTotalMicros(to target: CurrencyCode) -> Int64 {
        if let totalUsdMicros {
            return CurrencyCode.convertMicros(totalUsdMicros, from: .usd, to: target)
        }
        return items.reduce(Int64(0)) { sum, item in
            guard let micros = item.micros else { return sum }
            let source = item.currencyCode.flatMap { CurrencyCode(rawValue: $0.uppercased()) } ?? .krw
            return sum + CurrencyCode.convertMicros(micros, from: source, to: target)
        }
    }
}

struct ReceiptDetailItem: Equatable, Hashable {
    let id: UUID
    let externalBookId: String?
    let title: String?
    let author: String?
    let publisher: String?
    let pageCount: Int?
    let imageUrl: String?
    let isbn: String?
    let quantity: Int
    let micros: Int64?
    let currencyCode: String?
    let usdMicros: Int64?
    let exchangeRateToUsd: Double?
    let exchangeRateDate: String?
}

private struct ReceiptDetailDTO: Decodable {
    let id: UUID
    let createdAt: Date?
    let receiptAt: Date?
    let source: String
    let totalMicros: Int64?
    let totalUsdMicros: Int64?
    let type: String
    let items: [ReceiptDetailItemDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case receiptAt = "receipt_at"
        case source
        case totalMicros = "total_micros"
        case totalUsdMicros = "total_usd_micros"
        case type
        case items
    }
}

private struct ReceiptDetailItemDTO: Decodable {
    let id: UUID
    let externalBookId: String?
    let title: String?
    let author: String?
    let publisher: String?
    let pageCount: Int?
    let imageUrl: String?
    let isbn: String?
    let quantity: Int?
    let micros: Int64?
    let currencyCode: String?
    let usdMicros: Int64?
    let exchangeRateToUsd: Double?
    let exchangeRateDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case externalBookId = "external_book_id"
        case title
        case author
        case publisher
        case pageCount = "page_count"
        case imageUrl = "image_url"
        case isbn
        case quantity
        case micros
        case currencyCode = "currency_code"
        case usdMicros = "usd_micros"
        case exchangeRateToUsd = "exchange_rate_to_usd"
        case exchangeRateDate = "exchange_rate_date"
    }
}

private extension ReceiptDetailDTO {
    func toDomain() -> ReceiptDetail {
        ReceiptDetail(
            id: id,
            createdAt: createdAt,
            receiptAt: receiptAt,
            source: source,
            totalMicros: totalMicros,
            totalUsdMicros: totalUsdMicros,
            type: ReceiptType(rawValue: type) ?? .purchase,
            items: items.map { $0.toDomain() }
        )
    }
}

private extension ReceiptDetailItemDTO {
    func toDomain() -> ReceiptDetailItem {
        ReceiptDetailItem(
            id: id,
            externalBookId: externalBookId,
            title: title,
            author: author,
            publisher: publisher,
            pageCount: pageCount,
            imageUrl: imageUrl,
            isbn: isbn,
            quantity: max(quantity ?? 1, 1),
            micros: micros,
            currencyCode: currencyCode,
            usdMicros: usdMicros,
            exchangeRateToUsd: exchangeRateToUsd,
            exchangeRateDate: exchangeRateDate
        )
    }
}

// MARK: - RPC Param Models

private struct ListReceiptsPayload: Encodable {
    let pType: String?
    let pLimit: Int
    let pOffset: Int

    enum CodingKeys: String, CodingKey {
        case pType = "p_type"
        case pLimit = "p_limit"
        case pOffset = "p_offset"
    }
}

private struct GetReceiptDetailPayload: Encodable {
    let pReceiptId: UUID

    enum CodingKeys: String, CodingKey {
        case pReceiptId = "p_receipt_id"
    }
}

// MARK: - Service

struct ReceiptService {
    var createReceiptWithBooks: (
        _ source: String,
        _ totalMicros: Int64?,
        _ totalUsdMicros: Int64?,
        _ type: ReceiptType,
        _ receiptAt: Date?,
        _ items: [ReceiptRpcItem]
    ) async -> Result<UUID, AppError>

    var loadReceipts: (
        _ type: ReceiptType?,
        _ limit: Int,
        _ offset: Int
    ) async -> Result<[ReceiptSummary], AppError>

    var loadReceiptDetail: (
        _ receiptId: UUID
    ) async -> Result<ReceiptDetail, AppError>

    var deleteReceipt: (
        _ receiptId: UUID
    ) async -> Result<UUID, AppError>
}

extension ReceiptService {
    static func live(client: SupabaseClient) -> Self {
        let receiptsTable = "receipts"
        let createRpcName = "create_receipt_with_books"
        let listRpcName = "list_receipts"
        let detailRpcName = "get_receipt_detail"

        return Self(
            createReceiptWithBooks: { source, totalMicros, totalUsdMicros, type, receiptAt, items in
                do {
                    let payload = CreateReceiptWithBooksPayload(
                        pSource: source,
                        pTotalMicros: totalMicros,
                        pTotalUsdMicros: totalUsdMicros,
                        pType: type.rawValue,
                        pReceiptAt: receiptAt,
                        pItems: items
                    )

                    let response: PostgrestResponse<UUID> = try await client
                        .rpc(createRpcName, params: payload)
                        .single()
                        .execute()

                    return .success(response.value)
                } catch {
                    #if DEBUG
                    print("[DEBUG] createReceiptWithBooks error: \(error)")
                    #endif
                    return .failure(
                        .storage(
                            code: "CREATE_RECEIPT_WITH_BOOKS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            loadReceipts: { type, limit, offset in
                do {
                    let payload = ListReceiptsPayload(
                        pType: type?.rawValue,
                        pLimit: limit,
                        pOffset: offset
                    )

                    let response: PostgrestResponse<[ReceiptSummaryDTO]> = try await client
                        .rpc(listRpcName, params: payload)
                        .execute()

                    return .success(response.value.map { $0.toDomain() })
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_RECEIPTS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            loadReceiptDetail: { receiptId in
                do {
                    let payload = GetReceiptDetailPayload(
                        pReceiptId: receiptId
                    )

                    let response: PostgrestResponse<ReceiptDetailDTO?> = try await client
                        .rpc(detailRpcName, params: payload)
                        .execute()

                    guard let dto = response.value else {
                        return .failure(
                            .storage(
                                code: "RECEIPT_NOT_FOUND",
                                status: 404,
                                message: "Receipt not found"
                            )
                        )
                    }

                    return .success(dto.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_RECEIPT_DETAIL_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            deleteReceipt: { receiptId in
                do {
                    try await client
                        .from(receiptsTable)
                        .delete()
                        .eq("id", value: receiptId.uuidString)
                        .execute()

                    return .success(receiptId)
                } catch {
                    return .failure(
                        .storage(
                            code: "DELETE_RECEIPT_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        )
    }
}
