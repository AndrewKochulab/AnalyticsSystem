import Foundation

/// A tracker together with the mapping and filtering chosen for it at registration.
///
/// Binding these three at registration — rather than baking them into a tracker
/// subclass — is what removes the need for an inheritance hierarchy among providers.
public struct AnalyticsRegistration: Sendable {
    public let tracker: any AnalyticsTracker
    public let mapper: AnalyticsEventMapper
    public let filter: AnalyticsEventFilter
    public let validator: AnalyticsRecordValidator

    public var id: AnalyticsTrackerID { tracker.id }

    public init(
        tracker: any AnalyticsTracker,
        mapper: AnalyticsEventMapper = AnalyticsEventMapper(),
        filter: AnalyticsEventFilter = .all,
        validator: AnalyticsRecordValidator = .default
    ) {
        self.tracker = tracker
        self.mapper = mapper
        self.filter = filter
        self.validator = validator
    }
}
