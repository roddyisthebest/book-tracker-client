//
//  AuthService.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//

import AuthenticationServices
import Supabase
import UIKit

struct AuthService {
    var signUp: (_ email: String, _ password: String) async throws -> Result<AuthResponse, AppError>
    var signIn: (_ email: String, _ password: String) async throws -> Result<Session, AppError>
    var appleSignIn: (_ idToken: String, _ nonce: String) async throws -> Result<Session, AppError>
    var googleSignIn: () async throws -> Result<Session, AppError>
    var signOut: () async throws -> Void
    var currentSession: () async throws -> Session?
    var authStateChanges: () -> AsyncStream<(AuthChangeEvent, Session?)>
    var deleteMyAppData: () async -> Result<Bool, AppError>
    var deleteAccountOnServer: () async -> Result<Void, AppError>
}

extension AuthService {
    static func live(client: SupabaseClient) -> Self {
        Self(
            signUp: { email, password in
                let res = try await client.auth.signUp(email: email, password: password)
                return .success(res)
            },
            signIn: { email, password in
                let session = try await client.auth.signIn(email: email, password: password)
                return .success(session)
            },
            appleSignIn: { idToken, nonce in
                let session = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .apple,
                        idToken: idToken,
                        nonce: nonce
                    )
                )
                return .success(session)
            },
            googleSignIn: {
                let redirectTo = URL(string: "booktracker://auth-callback")!

                let session = try await client.auth.signInWithOAuth(
                    provider: .google,
                    redirectTo: redirectTo
                ) { (webSession: ASWebAuthenticationSession) in
                    webSession.presentationContextProvider = KeyWindowPresentationContextProvider.shared
                    webSession.prefersEphemeralWebBrowserSession = false
                }
                return .success(session)
            },
            signOut: {
                try await client.auth.signOut()
            },
            currentSession: {
                try await client.auth.session
            },
            authStateChanges: {
                AsyncStream { continuation in
                    let task = Task {
                        for await (event, session) in client.auth.authStateChanges {
                            continuation.yield((event, session))
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in
                        task.cancel()
                    }
                }
            },
            deleteMyAppData: {
                do {
                    _ = try await client
                        .rpc("delete_my_app_data")
                        .execute()
                    return .success(true)
                } catch {
                    return .failure(.unknown(message: error.localizedDescription))
                }
            },
            deleteAccountOnServer: {
                do {
                    let session = try await client.auth.session
                    let accessToken = session.accessToken

                    guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
                          let url = URL(string: "\(baseURL)/functions/v1/delete-account") else {
                        return .failure(.unknown(message: "Invalid Supabase URL"))
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let (_, response) = try await URLSession.shared.data(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode
                        return .failure(.function(status: statusCode, message: "Failed to delete account"))
                    }

                    return .success(())
                } catch {
                    return .failure(AppError.map(error))
                }
            }
        )
    }
}

final class KeyWindowPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = KeyWindowPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
