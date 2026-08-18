import Foundation

/// A destination for analytics.
///
/// Every requirement has a default no-op implementation, so a provider implements
/// only what it genuinely supports rather than inheriting methods it must stub out.
///
/// All requirements are `async`, which lets a conformer be an `actor`, a
/// `@MainActor` class, or a stateless `struct` — the caller does not care. Note that
/// there is deliberately **no `init` requirement**: nothing in this library ever
/// constructs a tracker, so a provider needing an API token can simply make that its
/// only initializer instead of trapping in an inherited one.
public protocol AnalyticsTracker: Sendable {
    var id: AnalyticsTrackerID { get }

    /// Boot the underlying SDK. Called once per registration.
    func start(with context: AnalyticsStartContext) async

    /// Toggle collection, e.g. for a privacy opt-out.
    func setEnabled(_ isEnabled: Bool) async

    /// Associate subsequent activity with the generated anonymous identity.
    func identify(anonymousID: AnalyticsID) async

    func logIn(user: AnalyticsUser) async

    func logOut() async

    /// Report an already-mapped record. Mapping is the system's responsibility, so
    /// trackers never see raw events.
    func record(_ record: AnalyticsRecord) async
}

public extension AnalyticsTracker {
    func start(with context: AnalyticsStartContext) async {}
    func setEnabled(_ isEnabled: Bool) async {}
    func identify(anonymousID: AnalyticsID) async {}
    func logIn(user: AnalyticsUser) async {}
    func logOut() async {}
}
