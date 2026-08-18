import Foundation

/// Type-level facts about an event, available to filters without touching the
/// event instance itself.
public struct AnalyticsEventDescriptor: Hashable, Sendable {
    public let category: AnalyticsEventCategory
    public let typeID: ObjectIdentifier
    public let name: AnalyticsEventName

    public init(
        category: AnalyticsEventCategory,
        typeID: ObjectIdentifier,
        name: AnalyticsEventName
    ) {
        self.category = category
        self.typeID = typeID
        self.name = name
    }

    public init<Event: AnalyticsEvent>(_ event: Event) {
        self.init(
            category: Event.category,
            typeID: ObjectIdentifier(Event.self),
            name: event.name
        )
    }
}
