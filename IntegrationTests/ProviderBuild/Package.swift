// swift-tools-version: 6.1

import PackageDescription

// A build-only consumer of AnalyticsSystem with *every* provider trait enabled.
//
// The root package builds green with its default (empty) trait set, which means a
// plain `swift build` never compiles a single provider body — precisely the blind
// spot that let the v1 package sit broken behind a green CI badge for years.
//
// This package closes it: it is compiled for an iOS destination in CI, so the real
// Firebase, Facebook, Mixpanel and Bugsnag adapter code must type-check against the
// real SDKs. Facebook in particular only has a body on iOS.
let package = Package(
    name: "ProviderBuild",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ProviderBuild", targets: ["ProviderBuild"])
    ],
    dependencies: [
        .package(
            name: "AnalyticsSystem",
            path: "../..",
            traits: ["Firebase", "Facebook", "Mixpanel", "Bugsnag"]
        )
    ],
    targets: [
        .target(
            name: "ProviderBuild",
            dependencies: [
                .product(name: "AnalyticsSystem", package: "AnalyticsSystem"),
                .product(name: "FirebaseProvider", package: "AnalyticsSystem"),
                .product(name: "FacebookProvider", package: "AnalyticsSystem"),
                .product(name: "MixpanelProvider", package: "AnalyticsSystem"),
                .product(name: "BugsnagProvider", package: "AnalyticsSystem")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
