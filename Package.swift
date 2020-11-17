// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalyticsSystem",
    platforms: [.iOS("9.3"), .macOS(.v10_12), .tvOS(.v10), .watchOS(.v6)],
    products: [
        .library(
            name: "MixpanelProvider",
            targets: ["MixpanelProvider"]
        ),
        .library(
            name: "BugsnagProvider",
            targets: ["BugsnagProvider"]
        ),
        .library(
            name: "AnalyticsSystem",
            targets: ["AnalyticsSystem"]
        ),
    ],
    dependencies: [
         .package(
            name: "Mixpanel",
            url: "https://github.com/mixpanel/mixpanel-swift.git",
            from: "2.0.0"
         ),
        .package(
            name: "Bugsnag",
            url: "https://github.com/bugsnag/bugsnag-cocoa.git",
            from: "6.0.0"
        ),
    ],
    targets: [
        .target(
            name: "AnalyticsSystem",
            path: "Sources/AnalyticsSystem"
        ),
        .testTarget(
            name: "AnalyticsSystemTests",
            dependencies: ["AnalyticsSystem"]
        ),
        .target(
            name: "MixpanelProvider",
            dependencies: [
                "AnalyticsSystem",
                .product(
                    name: "Mixpanel",
                    package: "Mixpanel",
                    condition: .when(platforms: [.iOS])
                )
            ],
            path: "Sources/MixpanelProvider",
            swiftSettings: [
                .define("DECIDE", .when(platforms: [.iOS])),
            ]
        ),
        .target(
            name: "BugsnagProvider",
            dependencies: [
                "AnalyticsSystem",
                .product(
                    name: "Bugsnag",
                    package: "Bugsnag"
                )
            ],
            path: "Sources/BugsnagProvider"
        )
    ]
)
