import ProjectDescription

let project = Project(
    name: "BookTracker",
    settings: .settings(
        configurations: [
            .debug(
                name: "Debug",
                xcconfig: .relativeToRoot("Config/App-Debug.xcconfig")
            ),
            .release(
                name: "Release",
                xcconfig: .relativeToRoot("Config/App-Release.xcconfig")
            ),
        ]
    ),
    targets: [
        .target(
            name: "BookTracker",
            destinations: .iOS,
            product: .app,
            bundleId: "com.seongyeon.booktracker",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "SUPABASE_URL": "$(SUPABASE_URL)",
                    "SUPABASE_ANON_KEY": "$(SUPABASE_ANON_KEY)",
                    "ENV": "$(ENV)",
                    "GOOGLE_BOOKS_API_KEY": "$(GOOGLE_BOOKS_API_KEY)",
                    "CFBundleLocalizations": ["ko", "en", "ja"],
                    "CFBundleDevelopmentRegion": "ko",
                ]
            ),
            sources: ["BookTracker/Sources/**"],
            resources: ["BookTracker/Resources/**"],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "Supabase"),
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        xcconfig: .relativeToRoot("Config/App-Debug.xcconfig")
                    ),
                    .release(
                        name: "Release",
                        xcconfig: .relativeToRoot("Config/App-Release.xcconfig")
                    ),
                ]
            )
        ),
        .target(
            name: "BookTrackerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.seong.booktrackerTests",
            infoPlist: .default,
            sources: ["BookTracker/Tests/**"],
            dependencies: [.target(name: "BookTracker")]
        ),
    ],

    schemes: [
        .scheme(
            name: "BookTracker-Dev",
            buildAction: .buildAction(targets: [.target("BookTracker")]),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .debug),
            profileAction: .profileAction(configuration: .debug),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
        .scheme(
            name: "BookTracker-Prod",
            buildAction: .buildAction(targets: [.target("BookTracker")]),
            runAction: .runAction(configuration: .release),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .release)
        ),
    ]
)
