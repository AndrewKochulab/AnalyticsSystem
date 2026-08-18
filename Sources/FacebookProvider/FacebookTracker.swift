#if Facebook && os(iOS)

import AnalyticsSystem
import FBSDKCoreKit
import Foundation
import UIKit

/// Reports to Facebook App Events.
///
/// `@MainActor`-isolated because FBSDKCoreKit expects to be driven from the main
/// thread. The `AnalyticsTracker` requirements are all `async`, so this costs the
/// caller nothing and needs no lock of its own.
///
/// The v1 adapter called `AppEvents` and `Settings` as *static* types; both moved to
/// shared instances in SDK v12, which is one of the reasons the old package no longer
/// compiles against a current Facebook SDK.
@MainActor
public final class FacebookTracker: AnalyticsTracker {
    nonisolated public let id: AnalyticsTrackerID

    private let collectsAdvertiserID: Bool
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

    public init(
        id: AnalyticsTrackerID = .facebook,
        collectsAdvertiserID: Bool = false
    ) {
        self.id = id
        self.collectsAdvertiserID = collectsAdvertiserID
    }

    /// Supplies the launch options FBSDK wants, straight from the app delegate.
    ///
    /// This is deliberately *not* routed through `AnalyticsSystem`. UIKit launch
    /// options are `[UIApplication.LaunchOptionsKey: Any]`, which is not `Sendable`;
    /// carrying them through the cross-platform core would have required an unchecked
    /// conformance and leaked UIKit into tvOS and watchOS builds — exactly the v1 bug.
    ///
    /// ```swift
    /// func application(
    ///     _ application: UIApplication,
    ///     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
    /// ) -> Bool {
    ///     facebookTracker.handleLaunch(options: options)
    ///     Task { await analytics.start() }
    ///     return true
    /// }
    /// ```
    public func handleLaunch(options: [UIApplication.LaunchOptionsKey: Any]?) {
        launchOptions = options
    }

    // MARK: AnalyticsTracker

    public func start(with context: AnalyticsStartContext) async {
        Settings.shared.isAdvertiserIDCollectionEnabled = collectsAdvertiserID
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    public func setEnabled(_ isEnabled: Bool) async {
        Settings.shared.isAutoLogAppEventsEnabled = isEnabled
        Settings.shared.isAdvertiserIDCollectionEnabled = isEnabled && collectsAdvertiserID
    }

    public func identify(anonymousID: AnalyticsID) async {
        AppEvents.shared.userID = anonymousID.rawValue
    }

    public func logIn(user: AnalyticsUser) async {
        AppEvents.shared.userID = user.id.rawValue
        AppEvents.shared.setUser(
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            phone: nil,
            dateOfBirth: nil,
            gender: nil,
            city: nil,
            state: nil,
            zip: nil,
            country: nil
        )
    }

    public func logOut() async {
        AppEvents.shared.userID = nil
        AppEvents.shared.clearUserData()
    }

    public func record(_ record: AnalyticsRecord) async {
        AppEvents.shared.logEvent(
            AppEvents.Name(record.name),
            parameters: record.payload.facebookParameters
        )
    }
}

#elseif Facebook

import Foundation

@available(
    *,
    unavailable,
    message: "FacebookTracker requires iOS. The Facebook SDK does not support other Apple platforms."
)
public enum FacebookTracker {}

#else

import Foundation

@available(
    *,
    unavailable,
    message: """
    FacebookTracker requires the "Facebook" package trait. Add it to your dependency:
    .package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git", from: "2.0.0", traits: ["Facebook"])
    """
)
public enum FacebookTracker {}

#endif
