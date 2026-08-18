import Foundation

/// Carries an event through the dispatch queue **without erasing its concrete type**.
///
/// This is the structural fix for the v1 defect where `AnalyticsEvent` was erased to
/// an existential at the facade boundary and the concrete type then had to be
/// recovered downstream with `event as! Event`.
///
/// Here the generic parameter `Event` is captured by ``resolve`` at the call site and
/// stays statically known. Nothing on the event path performs a cast.
public struct AnalyticsEventEnvelope: Sendable {
    public let descriptor: AnalyticsEventDescriptor

    /// Renders the captured event through a mapper. `nil` means "this provider
    /// does not report this event".
    let resolve: @Sendable (AnalyticsEventMapper) -> AnalyticsRecord?

    public init<Event: AnalyticsEvent>(_ event: Event) {
        self.descriptor = AnalyticsEventDescriptor(event)
        self.resolve = { mapper in mapper.record(for: event) }
    }
}
