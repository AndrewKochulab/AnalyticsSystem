import Foundation

/// Something the system did that you would otherwise never find out about.
///
/// Analytics failures are silent by nature: a dropped event looks exactly like an
/// event that was never sent, and neither shows up in a dashboard. Every path that
/// discards data reports it here so it can be logged, asserted on in debug builds, or
/// counted in tests.
public enum AnalyticsDiagnostic: Hashable, Sendable {
    /// An event arrived before ``AnalyticsSystem/start(with:)`` and was held.
    case buffered(AnalyticsEventName)

    /// The startup buffer was full; the oldest held event was discarded.
    case bufferOverflow(dropped: AnalyticsEventName, limit: Int)

    /// An event was discarded because collection is disabled.
    case droppedWhileDisabled(AnalyticsEventName)

    /// A provider's mapper declined to render the event.
    case unmapped(AnalyticsEventName, tracker: AnalyticsTrackerID)

    /// A record failed validation for a provider and was not sent.
    case rejected(AnalyticsEventName, tracker: AnalyticsTrackerID, reason: String)

    /// A record was altered to satisfy a provider's constraints.
    case sanitized(from: AnalyticsEventName, to: AnalyticsEventName, tracker: AnalyticsTrackerID)
}

extension AnalyticsDiagnostic: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .buffered(name):
            "buffered '\(name)' until start()"
        case let .bufferOverflow(dropped, limit):
            "startup buffer full (limit \(limit)); dropped '\(dropped)'"
        case let .droppedWhileDisabled(name):
            "dropped '\(name)': collection is disabled"
        case let .unmapped(name, tracker):
            "'\(name)' not mapped for '\(tracker)'"
        case let .rejected(name, tracker, reason):
            "'\(name)' rejected by '\(tracker)': \(reason)"
        case let .sanitized(from, to, tracker):
            "'\(from)' sanitized to '\(to)' for '\(tracker)'"
        }
    }
}

/// Receives ``AnalyticsDiagnostic`` values. Called off the main actor.
public typealias AnalyticsDiagnosticHandler = @Sendable (AnalyticsDiagnostic) -> Void
