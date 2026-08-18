import Foundation

/// The name under which an event is reported.
public typealias AnalyticsEventName = String

/// A single analytics occurrence.
///
/// Conformers are plain `Sendable` values. The default rendering — name plus
/// payload — is used unless a tracker's ``AnalyticsEventMapper`` overrides it.
public protocol AnalyticsEvent: Sendable {
    /// Classification of this event *type*, used by ``AnalyticsEventFilter``.
    static var category: AnalyticsEventCategory { get }

    var name: AnalyticsEventName { get }
    var payload: AnalyticsPayload { get }
}

public extension AnalyticsEvent {
    static var category: AnalyticsEventCategory { .custom }
    var payload: AnalyticsPayload { .empty }
}
