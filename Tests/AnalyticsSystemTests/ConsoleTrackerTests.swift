import Testing
@testable import AnalyticsSystem

@Suite("ConsoleTracker")
struct ConsoleTrackerTests {
    @Test("Writes one line per event")
    func writesOneLinePerEvent() async throws {
        let sink = SpyLogSink()
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(ConsoleTracker(sink: sink))

        system.track(DiagnosticEvent())
        system.track(PurchaseEvent(sku: "sku", amount: 1))
        await system.flush()

        let events = sink.messages.filter { $0.contains("event:") }
        #expect(events.count == 2)
    }

    /// Regression test for v1's `ConsoleTracker.print`, which shadowed `Swift.print`
    /// and forwarded the variadic array, so every line rendered as `["…"]`.
    @Test("Output is not rendered as a bracketed array")
    func outputIsNotBracketed() async throws {
        let sink = SpyLogSink()
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(ConsoleTracker(sink: sink))

        system.track(DiagnosticEvent())
        await system.flush()

        let message = try #require(sink.messages.first { $0.contains("event:") })
        #expect(!message.hasPrefix("["))
        #expect(!message.contains("[\""))
        #expect(message.contains("diagnostic"))
    }

    @Test("Payload is rendered alongside the event name")
    func rendersPayload() async throws {
        let sink = SpyLogSink()
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(ConsoleTracker(sink: sink))

        system.track(SignUpEvent(userID: "7", method: .email))
        await system.flush()

        let message = try #require(sink.messages.first { $0.contains("event:") })
        #expect(message.contains("sign_up"))
        #expect(message.contains("user_id"))
    }
}
