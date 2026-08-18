#if Firebase && (os(iOS) || os(macOS) || os(tvOS) || os(visionOS))

import AnalyticsSystem
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Foundation

/// Reports to Firebase Analytics and Crashlytics.
///
/// Unlike v1 this adapter implements crash reporting for real: Crashlytics does
/// answer "did the previous run crash", so `didCrashOnLastLaunch()` no longer
/// unconditionally returns `false`.
public struct FirebaseTracker: AnalyticsTracker, CrashReportingTracker {
    public let id: AnalyticsTrackerID

    /// When `true`, `start` calls `FirebaseApp.configure()`. Set to `false` if the
    /// host app already configures Firebase in its own launch path — calling it
    /// twice logs a warning and ignores the second call.
    private let configuresFirebaseApp: Bool

    public init(
        id: AnalyticsTrackerID = .firebase,
        configuresFirebaseApp: Bool = true
    ) {
        self.id = id
        self.configuresFirebaseApp = configuresFirebaseApp
    }

    private var crashlytics: Crashlytics { .crashlytics() }

    // MARK: AnalyticsTracker

    public func start(with context: AnalyticsStartContext) async {
        guard configuresFirebaseApp, FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }

    public func setEnabled(_ isEnabled: Bool) async {
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
        crashlytics.setCrashlyticsCollectionEnabled(isEnabled)
    }

    public func identify(anonymousID: AnalyticsID) async {
        Analytics.setUserID(anonymousID.rawValue)
        crashlytics.setUserID(anonymousID.rawValue)
    }

    public func logIn(user: AnalyticsUser) async {
        Analytics.setUserID(user.id.rawValue)
        crashlytics.setUserID(user.id.rawValue)

        for (key, value) in user.traits.flattened() {
            Analytics.setUserProperty(value.firebaseUserPropertyValue, forName: key)
        }
    }

    public func logOut() async {
        Analytics.setUserID(nil)
        // Both parameters are nullable in Firebase 12; v1 passed `""` because it
        // assumed otherwise, which left an empty-string user on every crash report.
        crashlytics.setUserID(nil)
    }

    public func record(_ record: AnalyticsRecord) async {
        Analytics.logEvent(record.name, parameters: record.payload.firebaseParameters)
    }

    // MARK: CrashReportingTracker

    public func didCrashOnLastLaunch() async -> Bool {
        crashlytics.didCrashDuringPreviousExecution()
    }
}

#elseif Firebase

import Foundation

@available(
    *,
    unavailable,
    message: "FirebaseTracker requires iOS, macOS, tvOS or visionOS. Firebase Analytics has no watchOS support."
)
public enum FirebaseTracker {}

#else

import Foundation

@available(
    *,
    unavailable,
    message: """
    FirebaseTracker requires the "Firebase" package trait. Add it to your dependency:
    .package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git", from: "2.0.0", traits: ["Firebase"])
    """
)
public enum FirebaseTracker {}

#endif
