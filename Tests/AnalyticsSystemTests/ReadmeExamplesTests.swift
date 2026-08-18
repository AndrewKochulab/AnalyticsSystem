import Testing
@testable import AnalyticsSystem

// Every core-only code block in README.md, verbatim enough to type-check.
//
// This exists because *none* of the v1 README's examples compiled — the factory in
// the "Example" section never conformed to the protocol it was passed as, and the
// `.signUp` it filtered on did not exist. Documentation that cannot compile is worse
// than no documentation, so it is a build product here.
//
// Provider-specific blocks (Facebook, Firebase) are covered by
// IntegrationTests/ProviderBuild, which builds against the real SDKs.

// MARK: - "1. Describe your events"

enum ReadmeRegistrationMethod: String, AnalyticsValueConvertible {
    case email = "Email"
    case facebook = "Facebook"
}

struct ReadmeSignUpEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .authentication

    let userID: String
    let method: ReadmeRegistrationMethod

    var name: AnalyticsEventName { "sign_up" }
    var payload: AnalyticsPayload {
        ["user_id": .string(userID), "method": method.analyticsValue]
    }
}

struct ReadmePurchaseEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .commerce
    var name: AnalyticsEventName { "purchase" }
}

// MARK: - "Writing your own provider"

struct ReadmeMyTracker: AnalyticsTracker {
    let id: AnalyticsTrackerID = "my-tracker"

    func record(_ record: AnalyticsRecord) async {
        // send record.name and record.payload
    }
}

@Suite("ReadmeExamples")
struct ReadmeExamplesTests {
    /// "2. Register providers" and "3. Track".
    @Test("The quick-start example works end to end")
    func quickStart() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()

        try await analytics.register(ConsoleTracker(sink: SpyLogSink()))
        await analytics.start()

        analytics.track(ReadmeSignUpEvent(userID: "user-1", method: .email))
        await analytics.flush()
    }

    /// "Sending only some events to a provider".
    @Test("Composed filters admit the documented events")
    func composedFilter() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "spy")

        try await analytics.register(
            spy,
            filter: .categories(.authentication) || .only(ReadmePurchaseEvent.self)
        )

        analytics.track(ReadmeSignUpEvent(userID: "1", method: .email))
        analytics.track(ReadmePurchaseEvent())
        analytics.track(DiagnosticEvent())
        await analytics.flush()

        #expect(await spy.recordedEventNames == ["sign_up", "purchase"])
    }

    /// "Rendering an event differently for one provider".
    @Test("A layered mapper renames the event for one provider only")
    func layeredMapper() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()
        let overriding = SpyTracker(id: "overriding")
        let plain = SpyTracker(id: "plain")

        let common = AnalyticsEventMapper()

        let facebookMapper = AnalyticsEventMapper()
            .mapping(for: ReadmeSignUpEvent.self) { event in
                AnalyticsRecord(
                    name: "fb_mobile_complete_registration",
                    attributes: ["fb_registration_method": event.method]
                )
            }
            .overriding(common)

        try await analytics.register(overriding, mapper: facebookMapper)
        try await analytics.register(plain, mapper: common)

        analytics.track(ReadmeSignUpEvent(userID: "1", method: .facebook))
        await analytics.flush()

        #expect(await overriding.recordedEventNames == ["fb_mobile_complete_registration"])
        #expect(await plain.recordedEventNames == ["sign_up"])
    }

    /// "Identity".
    @Test("The identity example works")
    func identity() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "spy")
        try await analytics.register(spy)

        await analytics.logIn(
            user: AnalyticsUser(id: "user-1", firstName: "Ada", email: "ada@example.com")
        )
        await analytics.logOut()

        #expect(await spy.recordedCalls.contains(.logOut))
    }

    /// "Crash reporting" and "Writing your own provider".
    @Test("A custom tracker receives events and reports no crash")
    func customTracker() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()
        try await analytics.register(ReadmeMyTracker())

        analytics.track(ReadmePurchaseEvent())
        await analytics.flush()

        #expect(await !analytics.didCrashOnLastLaunch())
    }

    /// "Testing".
    @Test("The documented test setup is deterministic")
    func documentedTestSetup() async throws {
        let analytics = AnalyticsSystem(
            configuration: .init(
                store: InMemoryAnalyticsStore(),
                idGenerator: { AnalyticsID(rawValue: "fixed") }
            )
        )
        let spy = SpyTracker(id: "spy")
        try await analytics.register(spy)
        await analytics.start()

        analytics.track(ReadmeSignUpEvent(userID: "1", method: .email))
        await analytics.flush()

        #expect(await spy.identifiedIDs == ["fixed"])
        #expect(await spy.recordedEventNames == ["sign_up"])
    }
}

// MARK: - 2.1.0 additions

@Suite("ReadmeExamples2_1")
struct ReadmeExamples21Tests {
    /// "Attributes on every event".
    @Test("Global properties reach every record, with events winning")
    func globalProperties() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "spy")
        try await analytics.register(spy)

        await analytics.setGlobalProperties([
            "app_version": "2.1.0",
            "locale": "en_US"
        ])
        analytics.track(ReadmePurchaseEvent())
        await analytics.flush()

        let record = try #require(await spy.recordedEvents.first)
        #expect(record.payload["app_version"] == .string("2.1.0"))
        #expect(record.payload["locale"] == .string("en_US"))
    }

    /// "Seeing what you lose".
    @Test("The documented diagnostics handler receives drops")
    func diagnosticsHandler() async throws {
        let recorder = DiagnosticsRecorder()
        let analytics = AnalyticsSystem(
            configuration: .init(
                store: InMemoryAnalyticsStore(),
                startupBuffer: .disabled,
                diagnostics: recorder.handler
            )
        )
        try await analytics.register(SpyTracker(id: "spy"))

        await analytics.setEnabled(false)
        analytics.track(ReadmePurchaseEvent())
        await analytics.flush()

        #expect(!recorder.recorded.isEmpty)
    }

    /// "Flushing before the app goes away".
    @Test("flushProviders reaches providers")
    func flushProviders() async throws {
        let analytics = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "spy")
        try await analytics.register(spy)

        await analytics.flushProviders()

        #expect(await spy.recordedCalls.contains(.flushPendingEvents))
    }

    /// "3. Track" — the documented pre-start buffering behaviour.
    @Test("Launch-time events survive until start()")
    func launchEventsSurvive() async throws {
        let analytics = AnalyticsSystem.makeTestSystem(startupBuffer: .default)

        analytics.track(ReadmePurchaseEvent())

        let spy = SpyTracker(id: "spy")
        try await analytics.register(spy)
        await analytics.start()
        await analytics.flush()

        #expect(await spy.recordedEventNames == ["purchase"])
    }
}
