//
//  Error.swift
//  BookTracker
//
//  Created by 배성연 on 3/1/26.
//
import Foundation
import Supabase

enum AppError: Error, Equatable {
    case auth(code: String?, status: Int?, message: String)
    case client(code: String, message: String)
    case storage(code: String?, status: Int?, message: String)
    case function(status: Int?, message: String)
    case network(message: String)
    case unauthorized
    case rateLimited
    case unknown(message: String)
}

extension AppError {
    static func map(_ error: Error) -> AppError {
        if let app = error as? AppError { return app }

        if let auth = error as? AuthError {
            // 네 AuthError는 케이스가 적으니 여기서 바로 변환
            switch auth {
            case .api(let message, let errorCode, _, let response):
                return .auth(code: errorCode.rawValue, status: response.statusCode, message: message)

            default:
                return .unauthorized
            }
        }

        if let urlError = error as? URLError {
            return .network(message: urlError.localizedDescription)
        }

        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return .network(message: ns.localizedDescription)
        }

        if let st = error as? StorageError {
            let statusInt = Int(st.statusCode ?? "")
            if statusInt == 401 || statusInt == 403 { return .unauthorized }
            if statusInt == 429 { return .rateLimited }
            return .storage(code: st.error, status: statusInt, message: st.message)
        }

        if let fn = error as? FunctionsError {
            // FunctionsError는 "non-2xx" 같은 케이스를 표현함
            // 실제로 statusCode/description 접근 방식은 버전별 차이가 있을 수 있음 → 아래는 안전한 fallback 중심
            let message = String(describing: fn)
            // status를 직접 꺼낼 수 있으면 넣고, 못 꺼내면 nil
            return .function(status: nil, message: message)
        }

        return .unknown(message: String(describing: error))
    }
}
