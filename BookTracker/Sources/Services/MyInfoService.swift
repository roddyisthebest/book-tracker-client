//
//  MyInfoService.swift
//  BookTracker
//
//  Created by 배성연 on 3/24/26.
//

import Foundation
import Supabase

struct MyProfile: Equatable, Codable, Hashable {
    let id: UUID
    var name: String?
    let role: String
    let phoneToken: String?
    let createdAt: Date?
    let deletedAt: Date?
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
    let createdAt: Date?
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case role
        case phoneToken = "phone_token"
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
            createdAt: createdAt,
            deletedAt: deletedAt
        )
    }
}

struct MyInfoService {
    var loadProfile: () async -> Result<MyProfile, AppError>
    var loadAuthInfo: () async -> Result<MyAuthInfo, AppError>
    var updateName: (_ name: String) async -> Result<MyProfile, AppError>
}

extension MyInfoService {
    static func live(client: SupabaseClient) -> Self {
        let profilesTable = "profiles"

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
            }
        )
    }
}
