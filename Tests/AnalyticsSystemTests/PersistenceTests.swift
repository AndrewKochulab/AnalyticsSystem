import Foundation
import Testing
@testable import AnalyticsSystem

@Suite("Persistence", .serialized)
struct PersistenceTests {
    /// A `UserDefaults` suite that is torn down when the test finishes.
    private final class TemporarySuite {
        let name: String
        let defaults: UserDefaults
        let store: UserDefaultsAnalyticsStore

        init() throws {
            let name = "com.analyticssystem.tests.\(UUID().uuidString)"
            self.name = name
            self.defaults = try #require(UserDefaults(suiteName: name))
            self.store = try #require(UserDefaultsAnalyticsStore(suiteName: name))
        }

        deinit {
            defaults.removePersistentDomain(forName: name)
        }
    }

    @Test("UserDefaults store round-trips a value")
    func userDefaultsRoundTrip() throws {
        let suite = try TemporarySuite()
        suite.store.setString("value", forKey: "key")

        #expect(suite.store.string(forKey: "key") == "value")
    }

    /// Regression test for v1's `@UserDefault` wrapper: assigning `nil` stored a null
    /// instead of removing the key, so clearing the anonymous ID did not clear it.
    @Test("Setting nil removes the key rather than storing a null")
    func nilRemovesKey() throws {
        let suite = try TemporarySuite()
        suite.store.setString("value", forKey: "key")
        suite.store.setString(nil, forKey: "key")

        #expect(suite.store.string(forKey: "key") == nil)
        #expect(suite.defaults.object(forKey: "key") == nil)
    }

    @Test("Rejects an unusable suite name")
    func rejectsGlobalDomain() {
        #expect(UserDefaultsAnalyticsStore(suiteName: "NSGlobalDomain") == nil)
    }

    @Test("In-memory store matches the protocol contract")
    func inMemoryContract() {
        let store = InMemoryAnalyticsStore()
        #expect(store.string(forKey: "key") == nil)

        store.setString("value", forKey: "key")
        #expect(store.string(forKey: "key") == "value")

        store.setString(nil, forKey: "key")
        #expect(store.string(forKey: "key") == nil)
    }

    @Test("Identity store mints once and persists")
    func identityStoreMintsOnce() async {
        let store = InMemoryAnalyticsStore()
        let identity = AnalyticsIdentityStore(store: store, generate: { "minted" })

        let first = await identity.currentAnonymousID()
        let second = await identity.currentAnonymousID()

        #expect(first == second)
        #expect(store.snapshot[AnalyticsIdentityStore.anonymousIDKey] == "minted")
    }

    @Test("A second identity store sharing the store reads the persisted ID")
    func identityStoreSharesPersistence() async {
        let store = InMemoryAnalyticsStore()
        let first = AnalyticsIdentityStore(store: store, generate: { "first" })
        _ = await first.currentAnonymousID()

        let second = AnalyticsIdentityStore(store: store, generate: { "second" })
        #expect(await second.currentAnonymousID() == "first")
    }

    @Test("Rotation replaces the persisted ID")
    func rotationReplacesID() async {
        let store = InMemoryAnalyticsStore()
        let identity = AnalyticsIdentityStore(
            store: store,
            generate: SequentialIDGenerator().generate
        )

        let original = await identity.currentAnonymousID()
        let rotated = await identity.rotateAnonymousID()

        #expect(original == "id-1")
        #expect(rotated == "id-2")
        #expect(store.snapshot[AnalyticsIdentityStore.anonymousIDKey] == "id-2")
    }
}
