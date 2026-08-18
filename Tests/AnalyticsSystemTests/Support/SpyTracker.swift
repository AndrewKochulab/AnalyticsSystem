import Foundation
@testable import AnalyticsSystem

/// Records every call the system makes, so behaviour can be asserted exactly.
///
/// Implemented as an `actor` rather than a lock-boxed class so the tests exercise the
/// same isolation shape a real provider would use.
actor SpyTracker: AnalyticsTracker, CrashReportingTracker {
    enum Call: Equatable, Sendable {
        case start(AnalyticsStartContext)
        case setEnabled(Bool)
        case identify(AnalyticsID)
        case logIn(AnalyticsUser)
        case logOut
        case record(AnalyticsRecord)
        case flushPendingEvents
    }

    nonisolated let id: AnalyticsTrackerID

    private var calls: [Call] = []
    private let crashedLastLaunch: Bool
    /// Nanoseconds, not `Duration`: `Duration` requires iOS 16 / watchOS 9,
    /// above this package's iOS 15 / watchOS 8 floor.
    private let recordDelay: UInt64?

    init(
        id: AnalyticsTrackerID,
        crashedLastLaunch: Bool = false,
        recordDelay: UInt64? = nil
    ) {
        self.id = id
        self.crashedLastLaunch = crashedLastLaunch
        self.recordDelay = recordDelay
    }

    // MARK: AnalyticsTracker

    func start(with context: AnalyticsStartContext) async {
        calls.append(.start(context))
    }

    func setEnabled(_ isEnabled: Bool) async {
        calls.append(.setEnabled(isEnabled))
    }

    func identify(anonymousID: AnalyticsID) async {
        calls.append(.identify(anonymousID))
    }

    func logIn(user: AnalyticsUser) async {
        calls.append(.logIn(user))
    }

    func logOut() async {
        calls.append(.logOut)
    }

    func flushPendingEvents() async {
        calls.append(.flushPendingEvents)
    }

    func record(_ record: AnalyticsRecord) async {
        if let recordDelay {
            try? await Task.sleep(nanoseconds: recordDelay)
        }
        calls.append(.record(record))
    }

    // MARK: CrashReportingTracker

    func didCrashOnLastLaunch() async -> Bool { crashedLastLaunch }

    // MARK: Assertions

    var recordedCalls: [Call] { calls }

    var recordedEvents: [AnalyticsRecord] {
        calls.compactMap { if case let .record(record) = $0 { record } else { nil } }
    }

    var recordedEventNames: [AnalyticsEventName] {
        recordedEvents.map(\.name)
    }

    var identifiedIDs: [AnalyticsID] {
        calls.compactMap { if case let .identify(id) = $0 { id } else { nil } }
    }
}

/// A tracker with no crash-reporting capability, used to prove the system consults
/// only conformers of `CrashReportingTracker`.
actor PlainTracker: AnalyticsTracker {
    nonisolated let id: AnalyticsTrackerID
    private(set) var recordCount = 0

    init(id: AnalyticsTrackerID) { self.id = id }

    func record(_ record: AnalyticsRecord) async { recordCount += 1 }
}
