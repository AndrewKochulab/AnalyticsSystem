import Foundation

/// Serialises access to the registered trackers.
///
/// v1 mutated a plain dictionary from arbitrary threads with no synchronisation.
/// An actor fixes that; the ``snapshot()`` discipline below keeps it from becoming a
/// bottleneck.
actor AnalyticsRegistry {
    private var registrations: [AnalyticsTrackerID: AnalyticsRegistration] = [:]

    /// Preserves registration order so fan-out is deterministic and testable.
    private var order: [AnalyticsTrackerID] = []

    func register(_ registration: AnalyticsRegistration) throws {
        let id = registration.id
        guard registrations[id] == nil else {
            throw AnalyticsError.duplicateTracker(id)
        }
        registrations[id] = registration
        order.append(id)
    }

    @discardableResult
    func unregister(_ id: AnalyticsTrackerID) throws -> AnalyticsRegistration {
        guard let removed = registrations.removeValue(forKey: id) else {
            throw AnalyticsError.unknownTracker(id)
        }
        order.removeAll { $0 == id }
        return removed
    }

    /// An ordered copy of the current registrations.
    ///
    /// Callers take a snapshot and then release the actor before awaiting any vendor
    /// SDK, so a slow provider can never block registration or another event.
    func snapshot() -> [AnalyticsRegistration] {
        order.compactMap { registrations[$0] }
    }

    var trackerIDs: [AnalyticsTrackerID] { order }

    func contains(_ id: AnalyticsTrackerID) -> Bool {
        registrations[id] != nil
    }

    var crashReporters: [any CrashReportingTracker] {
        snapshot().compactMap { $0.tracker as? any CrashReportingTracker }
    }
}
