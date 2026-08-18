import Testing
@testable import AnalyticsSystem

@Suite("Concurrency")
struct ConcurrencyTests {
    /// v1 mutated its tracker dictionary and enabled flag with no synchronisation.
    @Test("Concurrent tracking loses no events")
    func concurrentTrackingLosesNothing() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        let total = 500
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< total {
                group.addTask { system.track(DiagnosticEvent()) }
            }
        }
        await system.flush()

        #expect(await spy.recordedEvents.count == total)
    }

    @Test("Concurrent registration is serialised")
    func concurrentRegistrationIsSerialised() async throws {
        let system = AnalyticsSystem.makeTestSystem()

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 50 {
                group.addTask {
                    try? await system.register(SpyTracker(id: AnalyticsTrackerID(rawValue: "tracker-\(index)")))
                }
            }
        }

        #expect(await system.trackerIDs.count == 50)
    }

    /// Concurrent registration of a single ID must yield exactly one winner.
    @Test("Concurrent duplicate registration admits exactly one")
    func concurrentDuplicateRegistration() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let successes = Locked(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 25 {
                group.addTask {
                    do {
                        try await system.register(SpyTracker(id: .console))
                        successes.withLock { $0 += 1 }
                    } catch {}
                }
            }
        }

        #expect(successes.withLock { $0 } == 1)
        #expect(await system.trackerIDs == [.console])
    }
}
