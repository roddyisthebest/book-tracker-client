//
//  AppInfoService.swift
//  BookTracker
//
//  Created by 배성연 on 4/28/26.
//

import Foundation

struct AppInfoService {
    var appVersion: () -> String
    var buildNumber: () -> String
    var versionDisplay: () -> String
}

extension AppInfoService {
    static func live() -> Self {
        Self(
            appVersion: {
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
            },
            buildNumber: {
                Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
            },
            versionDisplay: {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
                return "v \(version) (\(build))"
            }
        )
    }
}
