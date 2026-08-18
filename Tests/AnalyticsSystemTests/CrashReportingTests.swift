import Testing
@testable import AnalyticsSystem

@Suite("CrashReporting")
struct CrashReportingTests {
    @Test("Reports a crash when any capable tracker saw one")
    func reportsWhenAnyTrackerCrashed() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(SpyTracker(id: "quiet", crashedLastLaunch: false))
        try await system.register(SpyTracker(id: "crashed", crashedLastLaunch: true))

        #expect(await system.didCrashOnLastLaunch())
    }

    @Test("Reports no crash when every capable tracker is quiet")
    func reportsFalseWhenNoneCrashed() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(SpyTracker(id: "a", crashedLastLaunch: false))

        #expect(await !system.didCrashOnLastLaunch())
    }

    @Test("Trackers without the capability are not consulted")
    func ignoresNonCapableTrackers() async throws {
        let system = AnalyticsSystem.makeTestSystem()
        try await system.register(PlainTracker(id: "plain"))

        #expect(await !system.didCrashOnLastLaunch())
    }
}
