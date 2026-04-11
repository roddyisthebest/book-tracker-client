//
//  SearchKeywordService.swift
//  BookTracker
//
//  Created by 배성연 on 4/7/26.
//

import Foundation
import Supabase

struct SearchKeyword: Equatable, Codable, Hashable, Identifiable {
    let id: UUID
    let keyword: String
    let searchCount: Int
    let createdAt: Date?
    let updatedAt: Date?
}

private struct SearchKeywordRow: Decodable {
    let id: UUID
    let keyword: String
    let searchCount: Int
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case keyword
        case searchCount = "search_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private extension SearchKeywordRow {
    func toDomain() -> SearchKeyword {
        SearchKeyword(
            id: id,
            keyword: keyword,
            searchCount: searchCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct ListSearchKeywordsPayload: Encodable {
    let pLimit: Int

    enum CodingKeys: String, CodingKey {
        case pLimit = "p_limit"
    }
}

private struct RecordSearchKeywordPayload: Encodable {
    let pKeyword: String

    enum CodingKeys: String, CodingKey {
        case pKeyword = "p_keyword"
    }
}

struct SearchKeywordService {
    var record: (_ keyword: String) async -> Result<SearchKeyword, AppError>
    var list: (_ limit: Int) async -> Result<[SearchKeyword], AppError>
}

extension SearchKeywordService {
    static func live(client: SupabaseClient) -> Self {
        let recordRpc = "record_search_keyword"
        let listRpc = "list_search_keywords"

        return Self(
            record: { keyword in
                do {
                    let normalized = keyword
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !normalized.isEmpty else {
                        return .failure(
                            .storage(
                                code: "EMPTY_SEARCH_KEYWORD",
                                status: 400,
                                message: "Keyword is empty"
                            )
                        )
                    }

                    let payload = RecordSearchKeywordPayload(pKeyword: normalized)

                    let response: PostgrestResponse<SearchKeywordRow> = try await client
                        .rpc(recordRpc, params: payload)
                        .execute()

                    return .success(response.value.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "RECORD_SEARCH_KEYWORD_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            list: { limit in
                do {
                    let payload = ListSearchKeywordsPayload(pLimit: limit)

                    let response: PostgrestResponse<[SearchKeywordRow]> = try await client
                        .rpc(listRpc, params: payload)
                        .execute()

                    return .success(response.value.map { $0.toDomain() })
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_SEARCH_KEYWORDS_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        )
    }
}
