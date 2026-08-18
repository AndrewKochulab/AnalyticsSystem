import Foundation

/// Translates events into provider-specific records.
///
/// This replaces v1's `AnalyticsTrackerFactory` protocol, the
/// `FactoryAnalyticsTracker<EventsFactory>` base class, and the documented pattern of
/// *subclassing* a factory to change one provider's rendering. A mapper is a value:
/// share a base across trackers and layer per-provider overrides on top.
///
/// ```swift
/// let facebook = AnalyticsEventMapper()
///     .mapping(for: SignUpEvent.self) { event in
///         AnalyticsRecord(name: "CompleteRegistration", payload: ["method": event.method])
///     }
///     .overriding(common)
/// ```
public struct AnalyticsEventMapper: Sendable {
    /// A per-event-type transform. Boxing in a nominal generic type (rather than a
    /// bare function) keeps the lookup's type relationship explicit.
    private struct Mapping<Event: AnalyticsEvent>: Sendable {
        let transform: @Sendable (Event) -> AnalyticsRecord?
    }

    /// Keyed by `ObjectIdentifier(Event.self)`. ``mapping(for:_:)`` is the sole
    /// insertion point and always stores a `Mapping<Event>` under that event's own
    /// key, so a key/value type mismatch is unrepresentable rather than merely unlikely.
    private var overrides: [ObjectIdentifier: any Sendable]

    public init() {
        self.overrides = [:]
    }

    // MARK: Building

    /// Overrides how one concrete event type is rendered.
    public func mapping<Event: AnalyticsEvent>(
        for type: Event.Type = Event.self,
        _ transform: @escaping @Sendable (Event) -> AnalyticsRecord?
    ) -> Self {
        var copy = self
        copy.overrides[ObjectIdentifier(Event.self)] = Mapping<Event>(transform: transform)
        return copy
    }

    /// Suppresses one event type entirely for this provider.
    public func ignoring<Event: AnalyticsEvent>(_ type: Event.Type) -> Self {
        mapping(for: Event.self) { _ in nil }
    }

    /// Layers this mapper's overrides on top of `base`.
    public func overriding(_ base: AnalyticsEventMapper) -> Self {
        var copy = base
        copy.overrides.merge(overrides) { _, new in new }
        return copy
    }

    // MARK: Rendering

    /// Renders `event`, falling back to the event's own default rendering.
    public func record<Event: AnalyticsEvent>(for event: Event) -> AnalyticsRecord? {
        if let mapping = overrides[ObjectIdentifier(Event.self)] as? Mapping<Event> {
            return mapping.transform(event)
        }
        return AnalyticsRecord(event)
    }
}
