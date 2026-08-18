import Testing
@testable import AnalyticsSystem

@Suite("EnableDisable")
struct EnableDisableTests {
    @Test("Disabling propagates to every tracker")
    func propagatesDisable() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.setEnabled(false)

        #expect(await spy.recordedCalls.contains(.setEnabled(false)))
        #expect(!system.isEnabled)
    }

    @Test("Events tracked while disabled are dropped")
    func dropsWhileDisabled() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.setEnabled(false)
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEvents.isEmpty)
    }

    @Test("Re-enabling resumes delivery without replaying the disabled window")
    func doesNotReplayDisabledWindow() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.setEnabled(false)
        system.track(PurchaseEvent(sku: "missed", amount: 1))
        await system.flush()

        await system.setEnabled(true)
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["diagnostic"])
    }

    @Test("Events queued before a disable still deliver")
    func queuedEventsSurviveDisable() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(DiagnosticEvent())
        await system.setEnabled(false)

        #expect(await spy.recordedEventNames == ["diagnostic"])
    }
}
