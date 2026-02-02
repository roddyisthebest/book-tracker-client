import ProjectDescription

let project = Project(
    name: "BookTracker",
    targets: [
        .target(
            name: "BookTracker",
            destinations: .iOS,
            product: .app,
            bundleId: "com.seong.booktracker",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["BookTracker/Sources/**"],
            resources: ["BookTracker/Resources/**"],
            dependencies: [
                .external(name:"ComposableArchitecture")
            ]
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
    ]
)
