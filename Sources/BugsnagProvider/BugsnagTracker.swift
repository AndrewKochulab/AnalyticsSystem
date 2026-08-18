#if Bugsnag

import AnalyticsSystem
import Bugsnag
import Foundation

/// Reports to Bugsnag.
///
/// Two v1 behaviours are corrected here. First, the API key is required by the only
/// initializer, so there is no inherited initializer left to trap in. Second, events
/// are actually recorded — v1 hardcoded its availability check to `false`, so this
/// tracker could never receive anything. Bugsnag's natural analogue of an event is a
/// breadcrumb, which is what gives crash reports their leading context.
///
/// An app that genuinely wants no breadcrumbs registers with `filter: .none`, which
/// makes that an explicit caller-side choice rather than a hidden library one.
public struct BugsnagTracker: AnalyticsTracker, CrashReportingTracker {
    public let id: AnalyticsTrackerID
    private let apiKey: String

    public init(id: AnalyticsTrackerID = .bugsnag, apiKey: String) {
        self.id = id
        self.apiKey = apiKey
    }

    // MARK: AnalyticsTracker

    public func start(with context: AnalyticsStartContext) async {
        guard !Bugsnag.isStarted() else { return }
        Bugsnag.start(with: BugsnagConfiguration(apiKey))
    }

    public func identify(anonymousID: AnalyticsID) async {
        Bugsnag.setUser(anonymousID.rawValue, withEmail: nil, andName: nil)
    }

    public func logIn(user: AnalyticsUser) async {
        Bugsnag.setUser(user.id.rawValue, withEmail: user.email, andName: user.fullName)
    }

    public func logOut() async {
        Bugsnag.setUser(nil, withEmail: nil, andName: nil)
    }

    public func record(_ record: AnalyticsRecord) async {
        Bugsnag.leaveBreadcrumb(
            record.name,
            metadata: record.payload.bugsnagMetadata,
            type: .state
        )
    }

    // MARK: CrashReportingTracker

    public func didCrashOnLastLaunch() async -> Bool {
        // `Bugsnag.appDidCrashLastLaunch()` is deprecated in 6.x in favour of this.
        Bugsnag.lastRunInfo?.crashed ?? false
    }
}

#else

import Foundation

@available(
    *,
    unavailable,
    message: """
    BugsnagTracker requires the "Bugsnag" package trait. Add it to your dependency:
    .package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git", from: "2.0.0", traits: ["Bugsnag"])
    """
)
public enum BugsnagTracker {}

#endif
