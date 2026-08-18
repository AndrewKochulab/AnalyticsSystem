import Testing
@testable import AnalyticsSystem

@Suite("Dispatch")
struct DispatchTests {
    @Test("An event reaches every registered tracker exactly once")
    func fansOutToAllTrackers() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let first = SpyTracker(id: "a")
        let second = SpyTracker(id: "b")
        try await system.register(first)
        try await system.register(second)

        system.track(SignUpEvent(userID: "7", method: .email))
        await system.flush()

        #expect(await first.recordedEventNames == ["sign_up"])
        #expect(await second.recordedEventNames == ["sign_up"])
    }

    @Test("Events are delivered in the order they were tracked")
    func preservesEventOrder() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(SignUpEvent(userID: "1", method: .email))
        system.track(PurchaseEvent(sku: "sku", amount: 1))
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["sign_up", "purchase", "diagnostic"])
    }

    /// A detached `Task` per call could not promise this; the serial queue can.
    @Test("Lifecycle calls and events stay mutually ordered")
    func preservesCrossOperationOrder() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        let user = AnalyticsUser(id: "user-1")
        await system.logIn(user: user)
        system.track(DiagnosticEvent())
        await system.flush()

        let calls = await spy.recordedCalls
        let logInIndex = try #require(calls.firstIndex { $0 == .logIn(user) })
        let recordIndex = try #require(calls.firstIndex {
            if case .record = $0 { true } else { false }
        })
        #expect(logInIndex < recordIndex)
    }

    /// v1 dispatched every event through `OperationQueue.main`.
    @Test("Tracking from a detached task still delivers")
    func tracksFromDetachedTask() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await Task.detached { system.track(DiagnosticEvent()) }.value
        await system.flush()

        #expect(await spy.recordedEventNames == ["diagnostic"])
    }

    @Test("A filter suppresses delivery to that tracker only")
    func filterIsPerTracker() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let filtered = SpyTracker(id: "filtered")
        let open = SpyTracker(id: "open")
        try await system.register(filtered, filter: .only(SignUpEvent.self))
        try await system.register(open)

        system.track(PurchaseEvent(sku: "sku", amount: 2))
        await system.flush()

        #expect(await filtered.recordedEvents.isEmpty)
        #expect(await open.recordedEventNames == ["purchase"])
    }

    @Test("A mapper returning nil suppresses delivery to that tracker only")
    func nilMappingSuppressesOneTracker() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let ignoring = SpyTracker(id: "ignoring")
        let open = SpyTracker(id: "open")
        try await system.register(
            ignoring,
            mapper: AnalyticsEventMapper().ignoring(PurchaseEvent.self)
        )
        try await system.register(open)

        system.track(PurchaseEvent(sku: "sku", amount: 2))
        await system.flush()

        #expect(await ignoring.recordedEvents.isEmpty)
        #expect(await open.recordedEventNames == ["purchase"])
    }

    @Test("A record with an empty name is dropped")
    func dropsInvalidRecord() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(NamelessEvent())
        await system.flush()

        #expect(await spy.recordedEvents.isEmpty)
    }

    @Test("flush() returns only after queued work is delivered")
    func flushDrainsQueue() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a", recordDelay: 5_000_000)
        try await system.register(spy)

        for _ in 0 ..< 10 { system.track(DiagnosticEvent()) }
        await system.flush()

        #expect(await spy.recordedEvents.count == 10)
    }

    @Test(
        "Category filters admit the expected events",
        arguments: [
            (AnalyticsEventCategory.authentication, ["sign_up"]),
            (AnalyticsEventCategory.commerce, ["purchase"]),
            (AnalyticsEventCategory.all, ["sign_up", "purchase", "diagnostic"]),
            (AnalyticsEventCategory.none, [])
        ]
    )
    func categoryFilters(
        category: AnalyticsEventCategory,
        expected: [AnalyticsEventName]
    ) async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy, filter: .categories(category))

        system.track(SignUpEvent(userID: "1", method: .email))
        system.track(PurchaseEvent(sku: "sku", amount: 1))
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == expected)
    }
}
