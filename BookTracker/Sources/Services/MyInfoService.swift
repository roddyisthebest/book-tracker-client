//
//  MyInfoService.swift
//  BookTracker
//
//  Created by 배성연 on 3/24/26.
//

import Foundation
import Supabase

struct MyProfile: Equatable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String?
    let role: String
    let phoneToken: String?
    var imageUuid: UUID?
    let createdAt: Date?
    let deletedAt: Date?

    var profileImageURL: URL? {
        guard let imageUuid else { return nil }
        return URL(string: "https://api.dicebear.com/9.x/adventurer/png?seed=\(imageUuid.uuidString)&size=200")
    }
}

struct MyAuthInfo: Equatable, Codable, Hashable {
    let email: String?
    let provider: String?
}

private struct ProfilesTableRow: Decodable {
    let id: UUID
    let name: String?
    let role: String?
    let phoneToken: String?
    let imageUuid: UUID?
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case role
        case phoneToken = "phone_token"
        case imageUuid = "image_uuid"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}

private extension ProfilesTableRow {
    func toDomain() -> MyProfile {
        MyProfile(
            id: id,
            name: name,
            role: role ?? "user",
            phoneToken: phoneToken,
            imageUuid: imageUuid,
            createdAt: createdAt,
            deletedAt: deletedAt
        )
    }
}

struct DeleteAllMyBookRelatedDataResult: Equatable, Codable, Hashable {
    let collectionItemsDeleted: Int
    let receiptItemsDeleted: Int
    let readingRecordsDeleted: Int
    let booksDeleted: Int
    let receiptsDeleted: Int
    let collectionsDeleted: Int
}

struct MyInfoService {
    var loadProfile: () async -> Result<MyProfile, AppError>
    var loadAuthInfo: () async -> Result<MyAuthInfo, AppError>
    var updateName: (_ name: String) async -> Result<MyProfile, AppError>
    var updateImageUuid: (_ imageUuid: UUID) async -> Result<MyProfile, AppError>
    var deleteAllMyBookRelatedData: () async -> Result<DeleteAllMyBookRelatedDataResult, AppError>
}

extension MyInfoService {
    static func live(client: SupabaseClient) -> Self {
        let profilesTable = "profiles"
        let deleteAllMyBookRelatedDataRpc = "delete_all_my_book_related_data"

        return Self(
            loadProfile: {
                do {
                    let userId = try await client.auth.user().id

                    let response: PostgrestResponse<[ProfilesTableRow]> = try await client
                        .from(profilesTable)
                        .select()
                        .eq("id", value: userId.uuidString)
                        .limit(1)
                        .execute()

                    guard let row = response.value.first else {
                        return .failure(
                            .storage(
                                code: "PROFILE_NOT_FOUND",
                                status: 404,
                                message: "Profile not found"
                            )
                        )
                    }

                    return .success(row.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_MY_PROFILE_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            loadAuthInfo: {
                do {
                    let user = try await client.auth.user()

                    return .success(
                        MyAuthInfo(
                            email: user.email,
                            provider: user.identities?.first?.provider
                        )
                    )
                } catch {
                    return .failure(
                        .storage(
                            code: "LOAD_MY_AUTH_INFO_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            updateName: { name in
                do {
                    let userId = try await client.auth.user().id
                    let payload = ["name": name]

                    let response: PostgrestResponse<[ProfilesTableRow]> = try await client
                        .from(profilesTable)
                        .update(payload, returning: .representation)
                        .eq("id", value: userId.uuidString)
                        .select()
                        .execute()

                    guard let row = response.value.first else {
                        return .failure(
                            .storage(
                                code: "PROFILE_NOT_UPDATED",
                                status: 404,
                                message: "Profile was not updated"
                            )
                        )
                    }

                    return .success(row.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "UPDATE_MY_PROFILE_NAME_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            updateImageUuid: { imageUuid in
                do {
                    let userId = try await client.auth.user().id
                    let payload = ["image_uuid": imageUuid.uuidString]

                    let response: PostgrestResponse<[ProfilesTableRow]> = try await client
                        .from(profilesTable)
                        .update(payload, returning: .representation)
                        .eq("id", value: userId.uuidString)
                        .select()
                        .execute()

                    guard let row = response.value.first else {
                        return .failure(
                            .storage(
                                code: "PROFILE_NOT_UPDATED",
                                status: 404,
                                message: "Profile image was not updated"
                            )
                        )
                    }

                    return .success(row.toDomain())
                } catch {
                    return .failure(
                        .storage(
                            code: "UPDATE_MY_PROFILE_IMAGE_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            },

            deleteAllMyBookRelatedData: {
                do {
                    let response: PostgrestResponse<DeleteAllMyBookRelatedDataResult> = try await client
                        .rpc(deleteAllMyBookRelatedDataRpc)
                        .execute()

                    return .success(response.value)
                } catch {
                    return .failure(
                        .storage(
                            code: "DELETE_ALL_MY_BOOK_RELATED_DATA_FAILED",
                            status: nil,
                            message: error.localizedDescription
                        )
                    )
                }
            }
        )
    }
}
