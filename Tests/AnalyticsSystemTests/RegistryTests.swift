import Testing
@testable import AnalyticsSystem

@Suite("Registry")
struct RegistryTests {
    @Test("Registers multiple trackers")
    func registersMultipleTrackers() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(SpyTracker(id: "a"))
        try await system.register(SpyTracker(id: "b"))

        #expect(Set(await system.trackerIDs) == ["a", "b"])
    }

    @Test("Rejects a duplicate identifier")
    func rejectsDuplicateIdentifier() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(SpyTracker(id: .console))

        await #expect(throws: AnalyticsError.duplicateTracker(.console)) {
            try await system.register(SpyTracker(id: .console))
        }
    }

    /// Regression test for the v1 registry, which keyed on `String(describing:)` and
    /// therefore could not tell two instances of one provider type apart.
    @Test("Two instances of the same tracker type coexist under distinct IDs")
    func sameTypeDistinctIDsCoexist() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let first = SpyTracker(id: "mixpanel.eu")
        let second = SpyTracker(id: "mixpanel.us")

        try await system.register(first)
        try await system.register(second)
        #expect(await system.trackerIDs.count == 2)

        try await system.unregister("mixpanel.eu")
        #expect(await system.trackerIDs == ["mixpanel.us"])
        #expect(await system.isRegistered("mixpanel.us"))
        #expect(await !system.isRegistered("mixpanel.eu"))
    }

    @Test("Unregistering an unknown identifier throws")
    func unregisterUnknownThrows() async throws {
        let system = AnalyticsSystem.makeTestSystem()

        await #expect(throws: AnalyticsError.unknownTracker("nope")) {
            try await system.unregister("nope")
        }
    }

    @Test("An unregistered tracker stops receiving events")
    func unregisteredTrackerReceivesNothing() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(DiagnosticEvent())
        await system.flush()
        try await system.unregister("a")
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEvents.count == 1)
    }

    @Test("A tracker registered after start still gets started and identified")
    func lateRegistrationIsStarted() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        await system.start()

        let spy = SpyTracker(id: "late")
        try await system.register(spy)
        await system.start()

        let calls = await spy.recordedCalls
        #expect(calls.contains { if case .start = $0 { true } else { false } })
        #expect(await spy.identifiedIDs.count == 1)
    }
}
