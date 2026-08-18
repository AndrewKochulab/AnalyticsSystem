import Testing
@testable import AnalyticsSystem

@Suite("Identity")
struct IdentityTests {
    @Test("start() identifies with a deterministic anonymous ID")
    func startIdentifiesDeterministically() async throws {
        let system = AnalyticsSystem.makeTestSystem(idGenerator: { "fixed-1" })
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.start()

        #expect(await spy.identifiedIDs == ["fixed-1"])
    }

    @Test("logIn reaches every tracker with the exact user")
    func logInPropagates() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        let user = AnalyticsUser(
            id: "user-1",
            firstName: "Ada",
            lastName: "Lovelace",
            email: "ada@example.com"
        )
        await system.logIn(user: user)

        #expect(await spy.recordedCalls.contains(.logIn(user)))
    }

    @Test("logOut rotates the anonymous identity")
    func logOutRotatesAnonymousID() async throws {
        let system = AnalyticsSystem.makeTestSystem(
            idGenerator: SequentialIDGenerator().generate
        )
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.start()
        await system.logOut()

        let identified = await spy.identifiedIDs
        #expect(identified.count == 2)
        #expect(identified[0] != identified[1])
        #expect(await spy.recordedCalls.contains(.logOut))
    }

    @Test("The anonymous ID is stable across reads and persists in the store")
    func anonymousIDIsStable() async throws {
        let store = InMemoryAnalyticsStore()
        let system = AnalyticsSystem.makeTestSystem(store: store, idGenerator: { "stable" })
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.start()
        await system.start()

        #expect(await spy.identifiedIDs == ["stable", "stable"])
        #expect(store.snapshot[AnalyticsIdentityStore.anonymousIDKey] == "stable")
    }
}
