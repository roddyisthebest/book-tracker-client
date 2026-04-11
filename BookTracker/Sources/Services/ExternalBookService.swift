//
//  ExternalBooksService.swift
//  BookTracker
//
//  Created by AI on 3/11/26.
//

import Foundation

// Functional client for fetching external books (Google Books API)
// Mirrors the pattern used by BookService: a struct with function properties and a live constructor.
struct ExternalBookService {
    enum ServiceError: Error, LocalizedError, Equatable {
        case missingAPIKey
        case invalidURL
        case transport(Error)
        case badStatus(code: Int, data: Data)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing GOOGLE_BOOKS_API_KEY in Info.plist"
            case .invalidURL:
                return "Failed to construct request URL"
            case let .transport(err):
                return "Network transport error: \(err.localizedDescription)"
            case let .badStatus(code, _):
                return "Server responded with status code: \(code)"
            case let .decoding(err):
                return "Failed to decode response: \(err.localizedDescription)"
            }
        }
    }

    var search: (_ query: String, _ startIndex: Int, _ maxResults: Int) async throws -> Result<[ExternalBook], ExternalBookService.ServiceError>
    var detail: (_ id: String) async throws -> Result<ExternalBook, ExternalBookService.ServiceError>
}

private struct VolumesSearchResponse: Decodable {
    let items: [ExternalBook]?
}

extension ExternalBookService {
    private static var currentLangRestrict: String? {
        let lang = Locale.current.language.languageCode?.identifier ?? ""
        switch lang {
        case "ko": return "ko"
        case "ja": return "ja"
        default: return nil
        }
    }

    static func live(langRestrict: String? = currentLangRestrict, session: URLSession = .shared) -> Self {
        func ensureAPIKey() throws -> String {
            if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_BOOKS_API_KEY") as? String, !key.isEmpty {
                return key
            }
            throw ExternalBookService.ServiceError.missingAPIKey
        }

        func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "www.googleapis.com"
            components.path = path
            components.queryItems = queryItems

            guard let url = components.url else { throw ExternalBookService.ServiceError.invalidURL }
            return url
        }

        func get(url: URL) async throws -> Data {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
                    throw ExternalBookService.ServiceError.badStatus(code: http.statusCode, data: data)
                }
                return data
            } catch {
                if let serviceError = error as? ExternalBookService.ServiceError { throw serviceError }
                throw ExternalBookService.ServiceError.transport(error)
            }
        }

        return Self(
            search: { query, startIndex, maxResults in
                do {
                    var queryItems: [URLQueryItem] = try [
                        URLQueryItem(name: "q", value: query),
                        URLQueryItem(name: "key", value: ensureAPIKey()),
                        URLQueryItem(name: "startIndex", value: String(startIndex)),
                        URLQueryItem(name: "maxResults", value: String(maxResults)),
                        URLQueryItem(name: "printType", value: "books")
                    ]
                    if let lang = langRestrict {
                        queryItems.append(URLQueryItem(name: "langRestrict", value: lang))
                    }
                    let url = try makeURL(path: "/books/v1/volumes", queryItems: queryItems)
                    let data = try await get(url: url)
                    let decoded = try JSONDecoder().decode(VolumesSearchResponse.self, from: data)
                    return .success(decoded.items ?? [])
                } catch let e as ExternalBookService.ServiceError {
                    return .failure(e)
                } catch {
                    return .failure(.transport(error))
                }
            },
            detail: { id in
                do {
                    var detailQueryItems: [URLQueryItem] = try [
                        URLQueryItem(name: "key", value: ensureAPIKey())
                    ]
                    if let lang = langRestrict {
                        detailQueryItems.append(URLQueryItem(name: "langRestrict", value: lang))
                    }
                    let url = try makeURL(
                        path: "/books/v1/volumes/\(id)",
                        queryItems: detailQueryItems
                    )
                    let data = try await get(url: url)
                    let book = try JSONDecoder().decode(ExternalBook.self, from: data)
                    return .success(book)
                } catch let e as ExternalBookService.ServiceError {
                    return .failure(e)
                } catch {
                    return .failure(.transport(error))
                }
            }
        )
    }
}

extension ExternalBookService.ServiceError {
    static func == (lhs: ExternalBookService.ServiceError, rhs: ExternalBookService.ServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey),
             (.invalidURL, .invalidURL):
            return true
        case let (.badStatus(code1, _), .badStatus(code2, _)):
            return code1 == code2
        case let (.transport(e1), .transport(e2)):
            let n1 = e1 as NSError
            let n2 = e2 as NSError
            return n1.domain == n2.domain && n1.code == n2.code
        case let (.decoding(e1), .decoding(e2)):
            return String(describing: e1) == String(describing: e2)
        default:
            return false
        }
    }
}
