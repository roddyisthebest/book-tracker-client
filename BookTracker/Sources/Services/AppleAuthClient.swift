//
//  AppleAuthClient.swift
//  BookTracker
//
//  Created by 배성연 on 3/2/26.
//

import AuthenticationServices
import CryptoKit
import Foundation

struct AppleAuthClient {
    struct Payload: Equatable {
        let idToken: String
        let nonce: String
        let fullName: PersonNameComponents? // 첫 로그인 때만 올 수도 있음(선택)
        let email: String? // 첫 로그인 때만 올 수도 있음(선택)
    }

    var signIn: () async throws -> Payload
}

// MARK: - Live

extension AppleAuthClient {
    static let live = AppleAuthClient(
        signIn: {
            let rawNonce = Nonce.make()
            let hashedNonce = Nonce.sha256(rawNonce)

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let result = try await AppleSignInRunner().run(request: request)

            guard let tokenData = result.credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8)
            else {
                throw AppleAuthError.missingIdentityToken
            }

            return Payload(
                idToken: idToken,
                nonce: rawNonce,
                fullName: result.credential.fullName,
                email: result.credential.email
            )
        }
    )
}

// MARK: - Runner (async wrapper)

private final class AppleSignInRunner: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<Result, Error>?

    struct Result {
        let credential: ASAuthorizationAppleIDCredential
    }

    func run(request: ASAuthorizationAppleIDRequest) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleAuthError.invalidCredentialType)
            continuation = nil
            return
        }
        continuation?.resume(returning: Result(credential: credential))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // SwiftUI에서는 가장 앞 window로 충분한 경우가 많음
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Nonce helpers

private enum Nonce {
    static func make(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(charset[Int.random(in: 0..<charset.count)])
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Errors

enum AppleAuthError: Error {
    case missingIdentityToken
    case invalidCredentialType
}
