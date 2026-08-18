import Testing
@testable import AnalyticsSystem

@Suite("StartupBuffer")
struct StartupBufferTests {
    @Test("Buffering is on by default")
    func bufferedByDefault() {
        #expect(AnalyticsStartupBuffer.default == .buffered(limit: 100))
        #expect(AnalyticsSystem.Configuration().startupBuffer == .buffered(limit: 100))
    }

    /// GAP 1 — before this, an event tracked before any tracker was registered was
    /// silently lost. That is precisely the app-launch case.
    @Test("An event tracked before any tracker is registered survives")
    func survivesTrackBeforeRegistration() async throws {
        let system = AnalyticsSystem.makeTestSystem(startupBuffer: .default)

        system.track(SignUpEvent(userID: "1", method: .email))

        let spy = SpyTracker(id: "late")
        try await system.register(spy)
        await system.start()
        await system.flush()

        #expect(await spy.recordedEventNames == ["sign_up"])
    }

    /// GAP 2 — before this, a provider received `record()` with no preceding
    /// `start()`, i.e. before its SDK had been initialised.
    @Test("A provider never receives an event before it has been started")
    func neverRecordsBeforeStart() async throws {
        let system = AnalyticsSystem.makeTestSystem(startupBuffer: .default)
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(DiagnosticEvent())
        await system.flush()
        #expect(await spy.recordedEvents.isEmpty)

        await system.start()
        await system.flush()

        let calls = await spy.recordedCalls
        let startIndex = try #require(calls.firstIndex { if case .start = $0 { true } else { false } })
        let recordIndex = try #require(calls.firstIndex { if case .record = $0 { true } else { false } })
        #expect(startIndex < recordIndex, "record() must never precede start()")
    }

    @Test("Held events replay in the order they were tracked")
    func replaysInOrder() async throws {
        let system = AnalyticsSystem.makeTestSystem(startupBuffer: .default)
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(SignUpEvent(userID: "1", method: .email))
        system.track(PurchaseEvent(sku: "sku", amount: 1))
        system.track(DiagnosticEvent())
        await system.start()
        await system.flush()

        #expect(await spy.recordedEventNames == ["sign_up", "purchase", "diagnostic"])
    }

    @Test("Events tracked after start are delivered immediately")
    func passThroughAfterStart() async throws {
        let system = AnalyticsSystem.makeTestSystem(startupBuffer: .default)
        let spy = SpyTracker(id: "a")
        try await system.register(spy)
        await system.start()

        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["diagnostic"])
    }

    @Test("The buffer is bounded, dropping oldest first and reporting it")
    func boundedBufferDropsOldest() async throws {
        let recorder = DiagnosticsRecorder()
        let system = AnalyticsSystem.makeTestSystem(
            startupBuffer: .buffered(limit: 2),
            diagnostics: recorder.handler
        )
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(SignUpEvent(userID: "1", method: .email))   // evicted
        system.track(PurchaseEvent(sku: "sku", amount: 1))
        system.track(DiagnosticEvent())
        await system.start()
        await system.flush()

        #expect(await spy.recordedEventNames == ["purchase", "diagnostic"])
        #expect(recorder.recorded.contains(.bufferOverflow(dropped: "sign_up", limit: 2)))
    }

    @Test("Disabling the buffer restores immediate delivery")
    func disabledBufferDeliversImmediately() async throws {
        let system = AnalyticsSystem.makeTestSystem(startupBuffer: .disabled)
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["diagnostic"])
    }

    @Test("Buffering is reported as a diagnostic")
    func reportsBuffering() async throws {
        let recorder = DiagnosticsRecorder()
        let system = AnalyticsSystem.makeTestSystem(
            startupBuffer: .default,
            diagnostics: recorder.handler
        )
        try await system.register(SpyTracker(id: "a"))

        system.track(DiagnosticEvent())
        await system.flush()

        #expect(recorder.recorded.contains(.buffered("diagnostic")))
    }
}
