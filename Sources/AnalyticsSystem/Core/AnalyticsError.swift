import Foundation

/// Errors surfaced by ``AnalyticsSystem`` registration.
public enum AnalyticsError: Error, Hashable, Sendable {
    /// A tracker with this identifier is already registered.
    case duplicateTracker(AnalyticsTrackerID)

    /// No tracker is registered under this identifier.
    case unknownTracker(AnalyticsTrackerID)
}

extension AnalyticsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .duplicateTracker(id):
            "A tracker with identifier '\(id)' is already registered. "
                + "Give the second instance a distinct AnalyticsTrackerID."
        case let .unknownTracker(id):
            "No tracker is registered with identifier '\(id)'."
        }
    }
}
