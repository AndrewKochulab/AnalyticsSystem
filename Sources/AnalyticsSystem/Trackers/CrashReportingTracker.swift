import Foundation

/// An opt-in capability for providers that also observe crashes.
///
/// v1 put `canObserveAppCrashes()` and `appDidCrashLastLaunch()` on every tracker,
/// so each provider had to stub both. Splitting the capability out means a provider
/// advertises crash reporting by conforming, and the system consults only those.
public protocol CrashReportingTracker: AnalyticsTracker {
    func didCrashOnLastLaunch() async -> Bool
}
