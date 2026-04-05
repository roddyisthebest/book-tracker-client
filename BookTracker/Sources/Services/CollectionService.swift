//
//  CollectionService.swift
//  BookTracker
//
//  Created by Assistant on 3/20/26.
//

import Foundation
import Supabase

// MARK: - Service Errors

enum CollectionServiceError: Error, LocalizedError {
    case notFound
    case emptyResponse
    case encodingFailed
    case emptyBookIds

    var errorDescription: String? {
        switch self {
        case .notFound: return "Collection not found"
        case .emptyResponse: return "Empty response from server"
        case .encodingFailed: return "Failed to encode payload"
        case .emptyBookIds: return "No book IDs provided"
        }
    }
}

// MARK: - Domain Models

struct CollectionPreviewBook: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let title: String?
    let thumbnail: String?
}

struct UserCollectionSummary: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let userId: UUID?
    var name: String?
    let isDefault: Bool
    let createdAt: Date?
    var description: String?
    let previewBooks: [CollectionPreviewBook]
    let bookCount: Int
}

struct UserCollection: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let userId: UUID?
    let name: String?
    let isDefault: Bool
    let createdAt: Date?
    let description: String?
}

struct CollectionItem: Identifiable, Codable, Hashable {
    let id: UUID
    let collectionId: UUID
    let bookId: UUID
    let createdAt: Date?
}

struct NewCollection {
    var name: String?
    var description: String?
    var isDefault: Bool
}

struct CollectionPatch {
    var name: String? = nil
    var description: String? = nil
    var isDefault: Bool? = nil
}

// MARK: - Database Row Models

private struct CollectionPreviewBookRow: Decodable {
    let id: UUID
    let title: String?
    let thumbnail: String?
}

private struct CollectionSummaryRow: Decodable {
    let id: UUID
    let userId: UUID?
    let name: String?
    let isDefault: Bool?
    let createdAt: Date?
    let description: String?
    let previewBooks: [CollectionPreviewBookRow]?
    let bookCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case isDefault = "is_default"
        case createdAt = "created_at"
        case description
        case previewBooks = "preview_books"
        case bookCount = "book_count"
    }
}

private struct GetCollectionSummariesParams: Encodable {
    let pLimit: Int
    let pOffset: Int

    enum CodingKeys: String, CodingKey {
        case pLimit = "p_limit"
        case pOffset = "p_offset"
    }
}

private struct SyncCollectionBooksParams: Encodable {
    let pCollectionId: UUID
    let pBookIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case pCollectionId = "p_collection_id"
        case pBookIds = "p_book_ids"
    }
}

private struct CollectionsTableRow: Decodable {
    let id: UUID
    let userId: UUID?
    let name: String?
    let isDefault: Bool?
    let createdAt: Date?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case isDefault = "is_default"
        case createdAt = "created_at"
        case description
    }
}

private struct CollectionsInsertRow: Encodable {
    let name: String?
    let description: String?
    let isDefault: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isDefault = "is_default"
    }
}

private struct CollectionsUpdateRow: Encodable {
    let name: String?
    let description: String?
    let isDefault: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isDefault = "is_default"
    }

    init(from patch: CollectionPatch) {
        self.name = patch.name
        self.description = patch.description
        self.isDefault = patch.isDefault
    }
}

private struct CollectionItemsTableRow: Decodable {
    let id: UUID
    let collectionId: UUID
    let bookId: UUID
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case collectionId = "collection_id"
        case bookId = "book_id"
        case createdAt = "created_at"
    }
}

private struct CollectionItemsInsertRow: Encodable {
    let collectionId: UUID
    let bookId: UUID

    enum CodingKeys: String, CodingKey {
        case collectionId = "collection_id"
        case bookId = "book_id"
    }
}

private struct CollectionBookRow: Decodable {
    let id: UUID
    let userId: UUID?
    let externalBookId: String?

    let title: String?
    let author: String?
    let publisher: String?
    let pageCount: Int?

    let imageUrl: String?
    let isbn: String?

    let status: String?
    let type: String?

    let startedAt: Date?
    let readCount: Int?
    let memo: String?

    let endedAt: Date?
    let score: Double?
    let review: String?

    let droppedReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case externalBookId = "external_book_id"
        case title
        case author
        case publisher
        case pageCount = "page_count"
        case imageUrl = "image_url"
        case isbn
        case status
        case type
        case startedAt = "started_at"
        case readCount = "read_count"
        case memo
        case endedAt = "ended_at"
        case score
        case review
        case droppedReason = "dropped_reason"
    }
}

private struct CreateCollectionWithBooksParams: Encodable {
    let pName: String?
    let pDescription: String?
    let pIsDefault: Bool
    let pBookIds: [UUID]?

    enum CodingKeys: String, CodingKey {
        case pName = "p_name"
        case pDescription = "p_description"
        case pIsDefault = "p_is_default"
        case pBookIds = "p_book_ids"
    }
}

private struct GetCollectionBooksParams: Encodable {
    let pCollectionId: UUID
    let pLimit: Int
    let pOffset: Int

    enum CodingKeys: String, CodingKey {
        case pCollectionId = "p_collection_id"
        case pLimit = "p_limit"
        case pOffset = "p_offset"
    }
}

private struct GetCollectionBooksCountParams: Encodable {
    let pCollectionId: UUID

    enum CodingKeys: String, CodingKey {
        case pCollectionId = "p_collection_id"
    }
}

private struct CreateCollectionWithBooksResponse: Decodable {
    let collection: CollectionsTableRow
    let bookIds: [UUID]?

    enum CodingKeys: String, CodingKey {
        case collection
        case bookIds = "book_ids"
    }
}

// MARK: - Mapping Helpers

private extension CollectionsTableRow {
    func toDomain() -> UserCollection {
        UserCollection(
            id: id,
            userId: userId,
            name: name,
            isDefault: isDefault ?? false,
            createdAt: createdAt,
            description: description
        )
    }
}

private extension CollectionItemsTableRow {
    func toDomain() -> CollectionItem {
        CollectionItem(
            id: id,
            collectionId: collectionId,
            bookId: bookId,
            createdAt: createdAt
        )
    }
}

private extension CollectionsInsertRow {
    init(from new: NewCollection) {
        self.name = new.name
        self.description = new.description
        self.isDefault = new.isDefault
    }
}

private extension CollectionPreviewBookRow {
    func toDomain() -> CollectionPreviewBook {
        CollectionPreviewBook(
            id: id,
            title: title,
            thumbnail: thumbnail
        )
    }
}

private extension CollectionSummaryRow {
    func toDomain() -> UserCollectionSummary {
        UserCollectionSummary(
            id: id,
            userId: userId,
            name: name,
            isDefault: isDefault ?? false,
            createdAt: createdAt,
            description: description,
            previewBooks: (previewBooks ?? []).map { $0.toDomain() },
            bookCount: bookCount ?? 0
        )
    }
}

extension UserCollectionSummary {
    func toUserCollection() -> UserCollection {
        UserCollection(
            id: id,
            userId: userId,
            name: name,
            isDefault: isDefault,
            createdAt: createdAt,
            description: description
        )
    }
}

extension UserCollection {
    func toSummary(
        previewBooks: [CollectionPreviewBook] = [],
        bookCount: Int = 0
    ) -> UserCollectionSummary {
        UserCollectionSummary(
            id: id,
            userId: userId,
            name: name,
            isDefault: isDefault,
            createdAt: createdAt,
            description: description,
            previewBooks: previewBooks,
            bookCount: bookCount
        )
    }

    static func make() -> Self {
        UserCollection(id: UUID(),
                       userId: UUID(),
                       name: "",
                       isDefault: false, createdAt: Date(),
                       description: "")
    }
}

extension UserCollectionSummary {
    func updating(from collection: UserCollection) -> UserCollectionSummary {
        UserCollectionSummary(
            id: collection.id,
            userId: collection.userId,
            name: collection.name,
            isDefault: collection.isDefault,
            createdAt: collection.createdAt,
            description: collection.description,
            previewBooks: previewBooks,
            bookCount: bookCount
        )
    }
}

private extension CollectionBookRow {
    func toDomain() -> Book {
        Book(
            id: id,
            userId: userId ?? UUID(),
            externalBookId: externalBookId,
            title: title ?? "",
            author: author ?? "",
            publisher: publisher ?? "",
            pageCount: pageCount,
            pageCountEditable: false,
            imageUrl: imageUrl,
            isbn: isbn ?? "",
            status: BookStatus(dbValue: status),
            type: BookType(dbValue: type),
            startedAt: startedAt,
            readCount: readCount,
            memo: memo,
            endedAt: endedAt,
            score: score,
            review: review,
            droppedReason: droppedReason
        )
    }
}

// MARK: - Service Definition

struct CollectionService {
    var create: (_ new: NewCollection) async -> Result<UserCollection, AppError>
    var addBooks: (_ collectionId: UUID, _ bookIds: [UUID]) async -> Result<[CollectionItem], AppError>
    var createWithBooks: (_ new: NewCollection, _ bookIds: [UUID]) async -> Result<UserCollection, AppError>
    var update: (_ id: UUID, _ patch: CollectionPatch) async -> Result<UserCollection, AppError>
    var list: () async -> Result<[UserCollection], AppError>
    var listSummaries: (_ limit: Int, _ offset: Int) async -> Result<[UserCollectionSummary], AppError>
    var listBooks: (_ collectionId: UUID, _ limit: Int, _ offset: Int) async -> Result<[Book], AppError>
    var syncBooks: (_ collectionId: UUID, _ bookIds: [UUID]) async -> Result<Bool, AppError>
    var items: (_ collectionId: UUID) async -> Result<[CollectionItem], AppError>
    var delete: (_ id: UUID) async -> Result<UUID, AppError>
    var deleteItem: (_ id: UUID) async -> Result<UUID, AppError>
}

extension CollectionService {
    static func live(client: SupabaseClient) -> Self {
        let collectionsTable = "collections"
        let itemsTable = "collection_items"

        func createCollection(_ new: NewCollection) async -> Result<UserCollection, AppError> {
            do {
                let payload = CollectionsInsertRow(from: new)

                let response: PostgrestResponse<[CollectionsTableRow]> = try await client
                    .from(collectionsTable)
                    .insert(payload, returning: .representation)
                    .select()
                    .execute()

                guard let row = response.value.first else {
                    return .failure(
                        .storage(
                            code: "EMPTY",
                            status: nil,
                            message: "Failed to insert collection"
                        )
                    )
                }

                return .success(row.toDomain())
            } catch {
                return .failure(
                    .storage(
                        code: "CREATE_COLLECTION_FAILED",
                        status: nil,
                        message: error.localizedDescription
                    )
                )
            }
        }

        func addBooksToCollection(_ collectionId: UUID, _ bookIds: [UUID]) async -> Result<[CollectionItem], AppError> {
            do {
                let uniqueIds = Array(Set(bookIds))

                guard !uniqueIds.isEmpty else {
                    return .failure(
                        .storage(
                            code: "EMPTY_BOOK_IDS",
                            status: 400,
                            message: CollectionServiceError.emptyBookIds.localizedDescription
                        )
                    )
                }

                let payloads = uniqueIds.map {
                    CollectionItemsInsertRow(collectionId: collectionId, bookId: $0)
                }

                let response: PostgrestResponse<[CollectionItemsTableRow]> = try await client
                    .from(itemsTable)
                    .insert(payloads, returning: .representation)
                    .select()
                    .execute()

                return .success(response.value.map { $0.toDomain() })
            } catch {
                return .failure(
                    .storage(
                        code: "ADD_BOOKS_FAILED",
                        status: nil,
                        message: error.localizedDescription
                    )
                )
            }
        }

        return Self(
            create: { new in
                await createCollection(new)
            },

            addBooks: { collectionId, bookIds in
                await addBooksToCollection(collectionId, bookIds)
            },

            createWithBooks: { new, bookIds in
                do {
                    let uniqueIds = Array(Set(bookIds))

                    let params = CreateCollectionWithBooksParams(
                        pName: new.name,
                        pDescription: new.description,
                        pIsDefault: new.isDefault,
                        pBookIds: uniqueIds.isEmpty ? nil : uniqueIds
                    )

                    let response: PostgrestResponse<CreateCollectionWithBooksResponse> = try await client
                        .rpc("create_collection_with_books", params: params)
                        .execute()

                    let collection = response.value.collection.toDomain()

                    return .success(collection)
                } catch {
                    return .failure(
                        .storage(
                            code: "CREATE_WITH_BOOKS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            update: { id, patch in
                do {
                    let payload = CollectionsUpdateRow(from: patch)

                    let response: PostgrestResponse<[CollectionsTableRow]> = try await client
                        .from(collectionsTable)
                        .update(payload, returning: .representation)
                        .eq("id", value: id.uuidString)
                        .select()
                        .execute()

                    guard let row = response.value.first else {
                        return .failure(
                            .storage(
                                code: "NOT_UPDATED",
                                status: 404,
                                message: "Collection was not updated. Check id or RLS policy."
                            )
                        )
                    }

                    return .success(row.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "UPDATE_COLLECTION_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            list: {
                do {
                    let response: PostgrestResponse<[CollectionsTableRow]> = try await client
                        .from(collectionsTable)
                        .select()
                        .order("created_at", ascending: false)
                        .execute()

                    return .success(response.value.map { $0.toDomain() })
                } catch {
                    return .failure(
                        .storage(
                            code: "LIST_COLLECTIONS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            listSummaries: { limit, offset in
                do {
                    let params = GetCollectionSummariesParams(
                        pLimit: limit,
                        pOffset: offset
                    )

                    let response: PostgrestResponse<[CollectionSummaryRow]> = try await client
                        .rpc("get_collection_summaries", params: params)
                        .execute()

                    return .success(response.value.map { $0.toDomain() })
                } catch {
                    return .failure(
                        .storage(
                            code: "LIST_COLLECTION_SUMMARIES_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            listBooks: { collectionId, limit, offset in
                do {
                    let params = GetCollectionBooksParams(
                        pCollectionId: collectionId,
                        pLimit: limit,
                        pOffset: offset
                    )

                    let response: PostgrestResponse<[CollectionBookRow]> = try await client
                        .rpc("get_collection_books", params: params)
                        .execute()

                    return .success(response.value.map { $0.toDomain() })
                } catch {
                    return .failure(
                        .storage(
                            code: "LIST_COLLECTION_BOOKS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            syncBooks: { collectionId, bookIds in
                do {
                    let params = SyncCollectionBooksParams(
                        pCollectionId: collectionId,
                        pBookIds: bookIds
                    )

                    _ = try await client
                        .rpc("sync_collection_books", params: params)
                        .execute()

                    return .success(true)
                } catch {
                    return .failure(
                        .storage(
                            code: "SYNC_COLLECTION_BOOKS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },
            items: { collectionId in
                do {
                    let response: PostgrestResponse<[CollectionItemsTableRow]> = try await client
                        .from(itemsTable)
                        .select()
                        .eq("collection_id", value: collectionId.uuidString)
                        .order("created_at", ascending: false)
                        .execute()

                    return .success(response.value.map { $0.toDomain() })
                } catch {
                    return .failure(
                        .storage(
                            code: "LIST_COLLECTION_ITEMS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            delete: { id in
                do {
                    let response: PostgrestResponse<[CollectionsTableRow]> = try await client
                        .from(collectionsTable)
                        .delete(returning: .representation)
                        .eq("id", value: id.uuidString)
                        .select()
                        .execute()

                    guard !response.value.isEmpty else {
                        return .failure(
                            .storage(
                                code: "NOT_DELETED",
                                status: 404,
                                message: "Collection was not deleted. Check id or RLS policy."
                            )
                        )
                    }

                    return .success(id)
                } catch {
                    return .failure(
                        .storage(
                            code: "DELETE_COLLECTION_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            deleteItem: { id in
                do {
                    let response: PostgrestResponse<[CollectionItemsTableRow]> = try await client
                        .from(itemsTable)
                        .delete(returning: .representation)
                        .eq("id", value: id.uuidString)
                        .select()
                        .execute()

                    guard !response.value.isEmpty else {
                        return .failure(
                            .storage(
                                code: "NOT_DELETED",
                                status: 404,
                                message: "Collection item was not deleted. Check id or RLS policy."
                            )
                        )
                    }

                    return .success(id)
                } catch {
                    return .failure(
                        .storage(
                            code: "DELETE_COLLECTION_ITEM_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        )
    }
}
