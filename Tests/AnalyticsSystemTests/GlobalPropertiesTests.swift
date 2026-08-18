import Testing
@testable import AnalyticsSystem

@Suite("GlobalProperties")
struct GlobalPropertiesTests {
    @Test("Global properties are merged into every record")
    func mergedIntoEveryRecord() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.setGlobalProperties(["app_version": "2.1.0", "locale": "en_US"])
        system.track(DiagnosticEvent())
        system.track(PurchaseEvent(sku: "sku", amount: 3))
        await system.flush()

        for record in await spy.recordedEvents {
            #expect(record.payload["app_version"] == .string("2.1.0"))
            #expect(record.payload["locale"] == .string("en_US"))
        }
    }

    @Test("Event attributes win over globals on key conflict")
    func eventAttributesWin() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.setGlobalProperties(["user_id": "global", "app_version": "2.1.0"])
        system.track(SignUpEvent(userID: "event", method: .email))
        await system.flush()

        let record = try #require(await spy.recordedEvents.first)
        #expect(record.payload["user_id"] == .string("event"))
        #expect(record.payload["app_version"] == .string("2.1.0"))
    }

    @Test("Globals only affect events tracked after they are set")
    func appliesFromWhenSet() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        system.track(DiagnosticEvent())
        await system.setGlobalProperties(["app_version": "2.1.0"])
        system.track(DiagnosticEvent())
        await system.flush()

        let records = await spy.recordedEvents
        #expect(records.count == 2)
        #expect(records[0].payload["app_version"] == nil)
        #expect(records[1].payload["app_version"] == .string("2.1.0"))
    }

    @Test("Setting globals again replaces the previous set")
    func replacesPreviousSet() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        let spy = SpyTracker(id: "a")
        try await system.register(spy)

        await system.setGlobalProperties(["a": "1"])
        await system.setGlobalProperties(["b": "2"])
        system.track(DiagnosticEvent())
        await system.flush()

        let record = try #require(await spy.recordedEvents.first)
        #expect(record.payload["a"] == nil)
        #expect(record.payload["b"] == .string("2"))
    }
}
