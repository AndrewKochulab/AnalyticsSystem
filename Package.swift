// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Traits

/// Provider adapters are gated behind package traits (SE-0450).
///
/// The default trait set is intentionally empty: a plain
/// `.package(url: "…/AnalyticsSystem.git", from: "2.0.0")` resolves with **zero**
/// third-party dependencies. Consumers opt in to only the providers they ship:
///
/// ```swift
/// .package(url: "…/AnalyticsSystem.git", from: "2.0.0", traits: ["Firebase", "Mixpanel"])
/// ```
///
/// Because each vendor SDK is referenced only from a trait-gated target dependency,
/// SwiftPM prunes the unused ones at resolution time — they are never cloned.
enum ProviderTrait {
    static let firebase = "Firebase"
    static let facebook = "Facebook"
    static let mixpanel = "Mixpanel"
    static let bugsnag = "Bugsnag"
}

/// Swift 6 language mode, applied uniformly to every target.
let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

let package = Package(
    name: "AnalyticsSystem",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "AnalyticsSystem", targets: ["AnalyticsSystem"]),
        .library(name: "FirebaseProvider", targets: ["FirebaseProvider"]),
        .library(name: "FacebookProvider", targets: ["FacebookProvider"]),
        .library(name: "MixpanelProvider", targets: ["MixpanelProvider"]),
        .library(name: "BugsnagProvider", targets: ["BugsnagProvider"])
    ],
    traits: [
        .trait(
            name: ProviderTrait.firebase,
            description: "Enables the Firebase Analytics + Crashlytics adapter (iOS, macOS, tvOS, visionOS)."
        ),
        .trait(
            name: ProviderTrait.facebook,
            description: "Enables the Facebook (FBSDKCoreKit) adapter (iOS only)."
        ),
        .trait(
            name: ProviderTrait.mixpanel,
            description: "Enables the Mixpanel adapter."
        ),
        .trait(
            name: ProviderTrait.bugsnag,
            description: "Enables the Bugsnag adapter."
        ),
        .default(enabledTraits: [])
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "12.17.0"
        ),
        .package(
            url: "https://github.com/facebook/facebook-ios-sdk.git",
            from: "18.1.0"
        ),
        .package(
            url: "https://github.com/mixpanel/mixpanel-swift.git",
            from: "6.5.1"
        ),
        .package(
            url: "https://github.com/bugsnag/bugsnag-cocoa.git",
            from: "6.37.0"
        )
    ],
    targets: [
        // MARK: Core — no third-party dependencies, all platforms.
        .target(
            name: "AnalyticsSystem",
            path: "Sources/AnalyticsSystem",
            swiftSettings: swiftSettings
        ),

        // MARK: Providers
        .target(
            name: "FirebaseProvider",
            dependencies: [
                "AnalyticsSystem",
                .product(
                    name: "FirebaseAnalytics",
                    package: "firebase-ios-sdk",
                    // Firebase gates FirebaseAnalytics to iOS/macCatalyst/macOS/tvOS.
                    // Claiming visionOS here compiles the adapter against a module
                    // that is not there.
                    condition: .when(
                        platforms: [.iOS, .macOS, .tvOS],
                        traits: [ProviderTrait.firebase]
                    )
                ),
                .product(
                    name: "FirebaseCrashlytics",
                    package: "firebase-ios-sdk",
                    // Firebase gates FirebaseAnalytics to iOS/macCatalyst/macOS/tvOS.
                    // Claiming visionOS here compiles the adapter against a module
                    // that is not there.
                    condition: .when(
                        platforms: [.iOS, .macOS, .tvOS],
                        traits: [ProviderTrait.firebase]
                    )
                )
            ],
            path: "Sources/FirebaseProvider",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FacebookProvider",
            dependencies: [
                "AnalyticsSystem",
                .product(
                    name: "FacebookCore",
                    package: "facebook-ios-sdk",
                    condition: .when(
                        platforms: [.iOS],
                        traits: [ProviderTrait.facebook]
                    )
                )
            ],
            path: "Sources/FacebookProvider",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MixpanelProvider",
            dependencies: [
                "AnalyticsSystem",
                .product(
                    name: "Mixpanel",
                    package: "mixpanel-swift",
                    condition: .when(
                        platforms: [.iOS, .macOS, .tvOS, .watchOS, .visionOS],
                        traits: [ProviderTrait.mixpanel]
                    )
                )
            ],
            path: "Sources/MixpanelProvider",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "BugsnagProvider",
            dependencies: [
                "AnalyticsSystem",
                .product(
                    name: "Bugsnag",
                    package: "bugsnag-cocoa",
                    condition: .when(traits: [ProviderTrait.bugsnag])
                )
            ],
            path: "Sources/BugsnagProvider",
            swiftSettings: swiftSettings
        ),

        // MARK: Tests
        .testTarget(
            name: "AnalyticsSystemTests",
            dependencies: ["AnalyticsSystem"],
            path: "Tests/AnalyticsSystemTests",
            swiftSettings: swiftSettings
        )
    ]
)
