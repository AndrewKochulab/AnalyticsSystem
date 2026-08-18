import Foundation

/// What to do with events tracked before ``AnalyticsSystem/start(with:)``.
///
/// This exists because both alternatives are wrong. Delivering such events reaches a
/// provider whose SDK has not been initialised — Firebase logs before
/// `FirebaseApp.configure()`, Mixpanel discards them. Dropping them loses exactly the
/// launch events that matter most, and loses them silently.
public enum AnalyticsStartupBuffer: Hashable, Sendable {
    /// Hold up to `limit` events and replay them, in order, once `start()` completes.
    /// When full, the oldest is discarded and reported as a diagnostic.
    case buffered(limit: Int)

    /// Deliver immediately, even if no provider has started yet.
    case disabled

    public static let `default` = AnalyticsStartupBuffer.buffered(limit: 100)
}
