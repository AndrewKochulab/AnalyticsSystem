import Foundation

/// Decides whether a tracker receives a given event.
///
/// Replaces v1's mutable `var isEventAvailable: IsEventAvailable { get set }`
/// protocol requirement. Removing that settable requirement is what lets trackers be
/// `Sendable` without any locking of their own; the choice now lives at registration.
public struct AnalyticsEventFilter: Sendable {
    let isAdmitted: @Sendable (AnalyticsEventDescriptor) -> Bool

    public init(_ predicate: @escaping @Sendable (AnalyticsEventDescriptor) -> Bool) {
        self.isAdmitted = predicate
    }

    public func admits(_ descriptor: AnalyticsEventDescriptor) -> Bool {
        isAdmitted(descriptor)
    }

    // MARK: Common filters

    public static let all = AnalyticsEventFilter { _ in true }
    public static let none = AnalyticsEventFilter { _ in false }

    public static func categories(_ categories: AnalyticsEventCategory) -> Self {
        AnalyticsEventFilter { !$0.category.isDisjoint(with: categories) }
    }

    public static func only<Event: AnalyticsEvent>(_ type: Event.Type) -> Self {
        let id = ObjectIdentifier(Event.self)
        return AnalyticsEventFilter { $0.typeID == id }
    }

    public static func excluding<Event: AnalyticsEvent>(_ type: Event.Type) -> Self {
        let id = ObjectIdentifier(Event.self)
        return AnalyticsEventFilter { $0.typeID != id }
    }

    public static func named(_ names: Set<AnalyticsEventName>) -> Self {
        AnalyticsEventFilter { names.contains($0.name) }
    }

    // MARK: Composition

    public static func && (lhs: Self, rhs: Self) -> Self {
        AnalyticsEventFilter { lhs.isAdmitted($0) && rhs.isAdmitted($0) }
    }

    public static func || (lhs: Self, rhs: Self) -> Self {
        AnalyticsEventFilter { lhs.isAdmitted($0) || rhs.isAdmitted($0) }
    }

    public static prefix func ! (filter: Self) -> Self {
        AnalyticsEventFilter { !filter.isAdmitted($0) }
    }
}
