//
//  StorageService.swift
//  BookTracker
//
//  Created by Claude on 5/2/26.
//

import Foundation
import Supabase

struct StorageService {
    var uploadBookCover: (_ imageData: Data) async -> Result<String, AppError>
}

extension StorageService {
    static func live(client: SupabaseClient) -> Self {
        let bucket = "book-covers"

        return Self(
            uploadBookCover: { imageData in
                do {
                    let session = try await client.auth.session
                    let userId = session.user.id.uuidString.lowercased()
                    let fileName = "\(userId)/\(UUID().uuidString).jpg"

                    try await client.storage
                        .from(bucket)
                        .upload(
                            path: fileName,
                            file: imageData,
                            options: FileOptions(contentType: "image/jpeg")
                        )

                    let publicURL = try client.storage
                        .from(bucket)
                        .getPublicURL(path: fileName)

                    return .success(publicURL.absoluteString)
                } catch {
                    return .failure(AppError.map(error))
                }
            }
        )
    }
}
