import Testing
@testable import AnalyticsSystem

@Suite("Diagnostics")
struct DiagnosticsTests {
    @Test("Dropping an event while disabled is reported")
    func reportsDropWhileDisabled() async throws {
        let recorder = DiagnosticsRecorder()
        let system = AnalyticsSystem.makeTestSystem(diagnostics: recorder.handler)
        try await system.register(SpyTracker(id: "a"))

        await system.setEnabled(false)
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(recorder.recorded.contains(.droppedWhileDisabled("diagnostic")))
    }

    @Test("An unmapped event is reported per tracker")
    func reportsUnmapped() async throws {
        let recorder = DiagnosticsRecorder()
        let system = AnalyticsSystem.makeTestSystem(diagnostics: recorder.handler)
        try await system.register(
            SpyTracker(id: "ignoring"),
            mapper: AnalyticsEventMapper().ignoring(PurchaseEvent.self)
        )

        system.track(PurchaseEvent(sku: "sku", amount: 1))
        await system.flush()

        #expect(recorder.recorded.contains(.unmapped("purchase", tracker: "ignoring")))
    }

    @Test("No handler means no crash and no cost")
    func handlerIsOptional() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(SpyTracker(id: "a"))
        await system.setEnabled(false)
        system.track(DiagnosticEvent())
        await system.flush()
    }

    @Test("Diagnostics render readably")
    func descriptionsAreReadable() {
        #expect(
            AnalyticsDiagnostic.rejected("e", tracker: "t", reason: "why").description
                == "'e' rejected by 't': why"
        )
        #expect(
            AnalyticsDiagnostic.bufferOverflow(dropped: "e", limit: 2).description
                == "startup buffer full (limit 2); dropped 'e'"
        )
    }
}

@Suite("ProviderFlush")
struct ProviderFlushTests {
    @Test("flushProviders reaches every tracker")
    func flushReachesEveryTracker() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let first = SpyTracker(id: "a")
        let second = SpyTracker(id: "b")
        try await system.register(first)
        try await system.register(second)

        await system.flushProviders()

        #expect(await first.recordedCalls.contains(.flushPendingEvents))
        #expect(await second.recordedCalls.contains(.flushPendingEvents))
    }

    @Test("flushProviders is ordered after events already tracked")
    func flushIsOrderedAfterEvents() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(DiagnosticEvent())
        await system.flushProviders()

        let calls = await spy.recordedCalls
        let recordIndex = try #require(calls.firstIndex { if case .record = $0 { true } else { false } })
        let flushIndex = try #require(calls.firstIndex(of: .flushPendingEvents))
        #expect(recordIndex < flushIndex)
    }

    @Test("A tracker that does not implement flush is unaffected")
    func defaultFlushIsNoOp() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(PlainTracker(id: "plain"))
        await system.flushProviders()
    }
}
