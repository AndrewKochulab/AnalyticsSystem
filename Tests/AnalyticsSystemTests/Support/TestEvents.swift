import Foundation
@testable import AnalyticsSystem

enum RegistrationMethod: String, AnalyticsValueConvertible {
    case email = "Email"
    case facebook = "Facebook"
}

struct SignUpEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .authentication

    let userID: String
    let method: RegistrationMethod

    var name: AnalyticsEventName { "sign_up" }
    var payload: AnalyticsPayload {
        ["user_id": .string(userID), "method": method.analyticsValue]
    }
}

struct PurchaseEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .commerce

    let sku: String
    let amount: Double

    var name: AnalyticsEventName { "purchase" }
    var payload: AnalyticsPayload {
        ["sku": .string(sku), "amount": .double(amount)]
    }
}

struct DiagnosticEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .diagnostics
    var name: AnalyticsEventName { "diagnostic" }
}

/// An event whose name is empty, to prove invalid records are dropped.
struct NamelessEvent: AnalyticsEvent {
    var name: AnalyticsEventName { "" }
}

/// A recording log sink for `ConsoleTracker`.
final class SpyLogSink: AnalyticsLogSink, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func write(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(message)
    }

    var messages: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

extension AnalyticsSystem {
    /// A system wired to in-memory persistence and a deterministic ID generator.
    static func makeTestSystem(
        store: any AnalyticsStore = InMemoryAnalyticsStore(),
        idGenerator: @escaping @Sendable () -> AnalyticsID = AnalyticsID.random
    ) -> AnalyticsSystem {
        AnalyticsSystem(
            configuration: Configuration(store: store, idGenerator: idGenerator)
        )
    }
}

/// A deterministic, concurrency-safe ID generator: `id-1`, `id-2`, …
struct SequentialIDGenerator: Sendable {
    private let counter = Locked(0)
    private let prefix: String

    init(prefix: String = "id") { self.prefix = prefix }

    var generate: @Sendable () -> AnalyticsID {
        { AnalyticsID(rawValue: "\(prefix)-\(counter.withLock { $0 += 1; return $0 })") }
    }
}
