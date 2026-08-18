import Foundation

/// A process-local store. Ships in the product because it is genuinely useful for
/// previews, unit tests, and opt-out builds that must not touch disk.
public final class InMemoryAnalyticsStore: AnalyticsStore {
    private let storage: Locked<[String: String]>

    public init(seed: [String: String] = [:]) {
        self.storage = Locked(seed)
    }

    public func string(forKey key: String) -> String? {
        storage.withLock { $0[key] }
    }

    public func setString(_ value: String?, forKey key: String) {
        storage.withLock { $0[key] = value }
    }

    public var snapshot: [String: String] {
        storage.withLock { $0 }
    }
}
