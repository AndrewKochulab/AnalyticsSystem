import Testing
@testable import AnalyticsSystem

@Suite("Validation")
struct ValidationTests {
    @Test("The default validator rejects an empty name")
    func defaultRejectsEmptyName() {
        if case .reject = AnalyticsRecordValidator.default(AnalyticsRecord(name: "")) {} else {
            Issue.record("expected rejection")
        }
        if case .accept = AnalyticsRecordValidator.default(AnalyticsRecord(name: "ok")) {} else {
            Issue.record("expected acceptance")
        }
    }

    @Test("The permissive validator accepts anything")
    func permissiveAcceptsAnything() {
        if case .accept = AnalyticsRecordValidator.permissive(AnalyticsRecord(name: "")) {} else {
            Issue.record("expected acceptance")
        }
    }

    @Test("A rejection suppresses delivery and is reported")
    func rejectionIsReported() async throws {
        let recorder = DiagnosticsRecorder()
        let system = AnalyticsSystem.makeTestSystem(diagnostics: recorder.handler)
        let spy = SpyTracker(id: "strict")

        let noPurchases = AnalyticsRecordValidator { record in
            record.name == "purchase"
                ? .reject(reason: "purchases are not allowed here")
                : .accept(record)
        }
        try await system.register(spy, validator: noPurchases)

        system.track(PurchaseEvent(sku: "sku", amount: 1))
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["diagnostic"])
        #expect(recorder.recorded.contains(
            .rejected("purchase", tracker: "strict", reason: "purchases are not allowed here")
        ))
    }

    @Test("Validation is per-tracker")
    func validationIsPerTracker() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let strict = SpyTracker(id: "strict")
        let lenient = SpyTracker(id: "lenient")

        try await system.register(strict, validator: AnalyticsRecordValidator { _ in
            .reject(reason: "nope")
        })
        try await system.register(lenient)

        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await strict.recordedEvents.isEmpty)
        #expect(await lenient.recordedEventNames == ["diagnostic"])
    }

    @Test("A sanitizing validator rewrites the record and reports it")
    func sanitizationIsReported() async throws {
        let recorder = DiagnosticsRecorder()
        let system = AnalyticsSystem.makeTestSystem(diagnostics: recorder.handler)
        let spy = SpyTracker(id: "trunc")

        let truncating = AnalyticsRecordValidator { record in
            .accept(AnalyticsRecord(name: String(record.name.prefix(4)), payload: record.payload))
        }
        try await system.register(spy, validator: truncating)

        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["diag"])
        #expect(recorder.recorded.contains(
            .sanitized(from: "diagnostic", to: "diag", tracker: "trunc")
        ))
    }

    @Test("combined(with:) runs the second validator on the first's output")
    func combinedChainsValidators() {
        let truncate = AnalyticsRecordValidator {
            .accept(AnalyticsRecord(name: String($0.name.prefix(4)), payload: $0.payload))
        }
        let rejectShort = AnalyticsRecordValidator {
            $0.name.count < 5 ? .reject(reason: "too short") : .accept($0)
        }

        if case let .reject(reason) = truncate.combined(with: rejectShort)(AnalyticsRecord(name: "diagnostic")) {
            #expect(reason == "too short")
        } else {
            Issue.record("expected the second validator to see the truncated name")
        }
    }
}
