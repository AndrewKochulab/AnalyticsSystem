import Foundation

/// A provider-ready rendering of an event: the exact name and attributes that will
/// be handed to a vendor SDK.
public struct AnalyticsRecord: Hashable, Sendable {
    public var name: AnalyticsEventName
    public var payload: AnalyticsPayload

    public init(name: AnalyticsEventName, payload: AnalyticsPayload = .empty) {
        self.name = name
        self.payload = payload
    }

    /// Builds a record from mixed convertible values.
    public init(name: AnalyticsEventName, attributes: [String: any AnalyticsValueConvertible]) {
        self.init(name: name, payload: AnalyticsPayload(attributes: attributes))
    }

    /// The default rendering: the event reports itself.
    public init(_ event: some AnalyticsEvent) {
        self.init(name: event.name, payload: event.payload)
    }

    /// Records without a name are dropped before reaching any tracker.
    public var isValid: Bool { !name.isEmpty }
}

extension AnalyticsRecord: CustomStringConvertible {
    public var description: String {
        payload.isEmpty ? name : "\(name) { \(payload) }"
    }
}
