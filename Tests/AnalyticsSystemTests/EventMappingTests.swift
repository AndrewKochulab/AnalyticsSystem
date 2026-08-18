import Testing
@testable import AnalyticsSystem

@Suite("EventMapping")
struct EventMappingTests {
    @Test("The default mapper renders the event itself")
    func defaultMapperRendersEvent() {
        let mapper = AnalyticsEventMapper()
        let record = mapper.record(for: SignUpEvent(userID: "7", method: .email))

        #expect(record?.name == "sign_up")
        #expect(record?.payload["user_id"] == .string("7"))
        #expect(record?.payload["method"] == .string("Email"))
    }

    /// The scenario the v1 README implemented by subclassing a factory class.
    @Test("An override applies to one tracker while another keeps the default")
    func overridePerTracker() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let facebook = SpyTracker(id: "facebook")
        let common = SpyTracker(id: "common")

        let facebookMapper = AnalyticsEventMapper()
            .mapping(for: SignUpEvent.self) { event in
                AnalyticsRecord(
                    name: "CompleteRegistration",
                    payload: ["method": event.method.analyticsValue]
                )
            }

        try await system.register(facebook, mapper: facebookMapper)
        try await system.register(common)

        system.track(SignUpEvent(userID: "7", method: .facebook))
        await system.flush()

        #expect(await facebook.recordedEventNames == ["CompleteRegistration"])
        #expect(await common.recordedEventNames == ["sign_up"])
    }

    @Test("overriding() layers overrides on top of a base mapper")
    func overridingLayersMappers() {
        let base = AnalyticsEventMapper()
            .mapping(for: SignUpEvent.self) { _ in AnalyticsRecord(name: "base_sign_up") }
            .mapping(for: PurchaseEvent.self) { _ in AnalyticsRecord(name: "base_purchase") }

        let layered = AnalyticsEventMapper()
            .mapping(for: SignUpEvent.self) { _ in AnalyticsRecord(name: "override_sign_up") }
            .overriding(base)

        #expect(layered.record(for: SignUpEvent(userID: "1", method: .email))?.name == "override_sign_up")
        #expect(layered.record(for: PurchaseEvent(sku: "s", amount: 1))?.name == "base_purchase")
    }

    @Test("ignoring() suppresses a single event type")
    func ignoringSuppressesOneType() {
        let mapper = AnalyticsEventMapper().ignoring(PurchaseEvent.self)

        #expect(mapper.record(for: PurchaseEvent(sku: "s", amount: 1)) == nil)
        #expect(mapper.record(for: DiagnosticEvent())?.name == "diagnostic")
    }

    /// Regression test for v1's `event as! Event`, which trapped whenever a factory
    /// was asked for an event type it had not been written against.
    @Test("An unmapped event type falls through to the default rendering without trapping")
    func unmappedEventDoesNotTrap() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")

        let mapper = AnalyticsEventMapper()
            .mapping(for: SignUpEvent.self) { _ in AnalyticsRecord(name: "mapped_sign_up") }
        try await system.register(spy, mapper: mapper)

        system.track(PurchaseEvent(sku: "sku", amount: 9.99))
        system.track(DiagnosticEvent())
        await system.flush()

        #expect(await spy.recordedEventNames == ["purchase", "diagnostic"])
    }
}
