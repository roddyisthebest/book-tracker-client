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
    let price: Int?
    let currencyCode: String?

    enum CodingKeys: String, CodingKey {
        case externalBookId
        case title
        case author
        case publisher
        case pageCount
        case imageUrl
        case isbn
        case quantity
        case price
        case currencyCode
    }
}

struct CreateReceiptWithBooksResult: Equatable, Codable, Hashable {
    let receiptId: UUID
    let bookIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case receiptId = "receipt_id"
        case bookIds = "book_ids"
    }
}

private struct CreateReceiptWithBooksPayload: Encodable {
    let pSource: String
    let pTotalPrice: Int?
    let pType: String
    let pReceiptAt: Date?
    let pItems: [ReceiptRpcItem]

    enum CodingKeys: String, CodingKey {
        case pSource = "p_source"
        case pTotalPrice = "p_total_price"
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
    let totalPrice: Int?
    let type: ReceiptType
    let firstBookTitle: String?
    let totalQuantity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case receiptAt = "receipt_at"
        case source
        case totalPrice = "total_price"
        case type
        case firstBookTitle = "first_book_title"
        case totalQuantity = "total_quantity"
    }
}

private struct ReceiptSummaryDTO: Decodable {
    let id: UUID
    let createdAt: String?
    let receiptAt: String?
    let source: String
    let totalPrice: Int?
    let type: String
    let firstBookTitle: String?
    let totalQuantity: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case receiptAt = "receipt_at"
        case source
        case totalPrice = "total_price"
        case type
        case firstBookTitle = "first_book_title"
        case totalQuantity = "total_quantity"
    }
}

private extension ReceiptSummaryDTO {
    func toDomain() -> ReceiptSummary {
        ReceiptSummary(
            id: id,
            createdAt: ReceiptDateParser.parse(createdAt),
            receiptAt: ReceiptDateParser.parse(receiptAt),
            source: source,
            totalPrice: totalPrice,
            type: ReceiptType(rawValue: type) ?? .purchase,
            firstBookTitle: firstBookTitle,
            totalQuantity: totalQuantity
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
    let totalPrice: Int?
    let type: ReceiptType
    let items: [ReceiptDetailItem]
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
    let price: Int?
    let currencyCode: String?
}

private struct ReceiptDetailDTO: Decodable {
    let id: UUID
    let createdAt: Date?
    let receiptAt: Date?
    let source: String
    let totalPrice: Int?
    let type: String
    let items: [ReceiptDetailItemDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case receiptAt = "receipt_at"
        case source
        case totalPrice = "total_price"
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
    let price: Int?
    let currencyCode: String?

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
        case price
        case currencyCode = "currency_code"
    }
}

private extension ReceiptDetailDTO {
    func toDomain() -> ReceiptDetail {
        ReceiptDetail(
            id: id,
            createdAt: createdAt,
            receiptAt: receiptAt,
            source: source,
            totalPrice: totalPrice,
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
            price: price,
            currencyCode: currencyCode
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
        _ totalPrice: Int?,
        _ type: ReceiptType,
        _ receiptAt: Date?,
        _ items: [ReceiptRpcItem]
    ) async -> Result<CreateReceiptWithBooksResult, AppError>

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
    ) async -> Result<Void, AppError>
}

extension ReceiptService {
    static func live(client: SupabaseClient) -> Self {
        let receiptsTable = "receipts"
        let createRpcName = "create_receipt_with_books"
        let listRpcName = "list_receipts"
        let detailRpcName = "get_receipt_detail"

        return Self(
            createReceiptWithBooks: { source, totalPrice, type, receiptAt, items in
                do {
                    let payload = CreateReceiptWithBooksPayload(
                        pSource: source,
                        pTotalPrice: totalPrice,
                        pType: type.rawValue,
                        pReceiptAt: receiptAt,
                        pItems: items
                    )

                    let response: PostgrestResponse<[CreateReceiptWithBooksResult]> = try await client
                        .rpc(createRpcName, params: payload)
                        .execute()

                    guard let result = response.value.first else {
                        return .failure(
                            .storage(
                                code: "RECEIPT_NOT_CREATED",
                                status: 404,
                                message: "Receipt was not created"
                            )
                        )
                    }

                    return .success(result)
                } catch {
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

                    return .success(())
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
