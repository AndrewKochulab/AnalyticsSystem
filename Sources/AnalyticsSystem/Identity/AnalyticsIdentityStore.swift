import Foundation

/// Owns the generated anonymous identity.
///
/// Both the backing store and the generator are injected, which is what makes
/// identity behaviour deterministically testable instead of UUID-flaky.
actor AnalyticsIdentityStore {
    static let anonymousIDKey = "com.analyticssystem.anonymousID"

    private let store: any AnalyticsStore
    private let generate: @Sendable () -> AnalyticsID
    private var cached: AnalyticsID?

    init(
        store: any AnalyticsStore,
        generate: @escaping @Sendable () -> AnalyticsID = AnalyticsID.random
    ) {
        self.store = store
        self.generate = generate
    }

    /// The persisted anonymous ID, minting and storing one on first use.
    func currentAnonymousID() -> AnalyticsID {
        if let cached { return cached }

        if let stored = store.string(forKey: Self.anonymousIDKey) {
            let id = AnalyticsID(rawValue: stored)
            cached = id
            return id
        }

        return mint()
    }

    /// Discards the current anonymous ID and mints a fresh one.
    ///
    /// Called on log out so the next session is not silently correlated with the
    /// previous user.
    @discardableResult
    func rotateAnonymousID() -> AnalyticsID {
        store.setString(nil, forKey: Self.anonymousIDKey)
        cached = nil
        return mint()
    }

    private func mint() -> AnalyticsID {
        let id = generate()
        store.setString(id.rawValue, forKey: Self.anonymousIDKey)
        cached = id
        return id
    }
}
