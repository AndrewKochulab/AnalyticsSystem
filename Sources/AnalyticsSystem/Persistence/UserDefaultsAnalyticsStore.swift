import Foundation

/// `UserDefaults`-backed persistence.
///
/// `UserDefaults` is thread-safe but not `Sendable`, so rather than reach for an
/// unsafe opt-out this store keeps only a validated *description* of which suite to
/// use and resolves the (process-cached) instance per access. That keeps the whole
/// package free of `nonisolated(unsafe)` and unchecked conformances.
public struct UserDefaultsAnalyticsStore: AnalyticsStore {
    private enum Source: Hashable, Sendable {
        case standard
        case suite(String)
    }

    private let source: Source

    /// Uses `UserDefaults.standard`.
    public init() {
        self.source = .standard
    }

    /// Uses the named suite.
    ///
    /// - Returns: `nil` if `suiteName` is not a usable suite — for example the app's
    ///   own bundle identifier, or `NSGlobalDomain`.
    public init?(suiteName: String) {
        guard UserDefaults(suiteName: suiteName) != nil else { return nil }
        self.source = .suite(suiteName)
    }

    /// Resolves the backing store. The suite name was validated in `init?`, so the
    /// fallback is unreachable in practice; it exists only to keep this total.
    private var defaults: UserDefaults {
        switch source {
        case .standard:
            .standard
        case let .suite(name):
            UserDefaults(suiteName: name) ?? .standard
        }
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func setString(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            // v1 assigned `nil` through a property wrapper, which stored a null
            // rather than removing the key — so "clearing" the anonymous ID left it
            // in place. Removal has to be explicit.
            defaults.removeObject(forKey: key)
        }
        // No `synchronize()`: deprecated since iOS 12 and a no-op.
    }
}
