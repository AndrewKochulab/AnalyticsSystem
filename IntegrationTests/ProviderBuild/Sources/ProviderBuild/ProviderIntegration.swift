import AnalyticsSystem
import BugsnagProvider
import FacebookProvider
import FirebaseProvider
import MixpanelProvider
import UIKit

/// Exercises the full public surface of every provider so that a signature drift in
/// any vendor SDK becomes a compile error here rather than a crash in production.
///
/// This is intentionally never executed — it is a type-checking fixture.
public enum ProviderIntegration {
    public static func wireEverything() async throws -> AnalyticsSystem {
        let analytics = AnalyticsSystem()

        // A base mapping shared by all providers…
        let common = AnalyticsEventMapper()
            .mapping(for: SignUpEvent.self) { event in
                AnalyticsRecord(name: "sign_up", attributes: ["method": event.method])
            }

        // …and a Facebook-specific override, layered by composition rather than by
        // subclassing a factory as v1 required.
        let facebookMapper = AnalyticsEventMapper()
            .mapping(for: SignUpEvent.self) { event in
                AnalyticsRecord(
                    name: "fb_mobile_complete_registration",
                    attributes: ["fb_registration_method": event.method]
                )
            }
            .overriding(common)

        try await analytics.register(FirebaseTracker(), mapper: common)
        try await analytics.register(MixpanelTracker(apiToken: "token"), mapper: common)
        try await analytics.register(BugsnagTracker(apiKey: "key"), mapper: common)
        try await analytics.register(
            await FacebookTracker(),
            mapper: facebookMapper,
            filter: .categories(.authentication)
        )
        try await analytics.register(ConsoleTracker())

        await analytics.start()
        analytics.track(SignUpEvent(method: .email))
        await analytics.logIn(user: AnalyticsUser(id: "user-1", email: "a@example.com"))
        await analytics.logOut()
        await analytics.setEnabled(false)
        _ = await analytics.didCrashOnLastLaunch()
        await analytics.flush()

        return analytics
    }

    /// The launch-options handoff documented in the README: UIKit types stay in the
    /// app and in this one provider, never in the cross-platform core.
    @MainActor
    public static func handleLaunch(
        tracker: FacebookTracker,
        options: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        tracker.handleLaunch(options: options)
    }
}

public enum RegistrationMethod: String, AnalyticsValueConvertible {
    case email = "Email"
    case facebook = "Facebook"
}

public struct SignUpEvent: AnalyticsEvent {
    public static let category: AnalyticsEventCategory = .authentication

    public let method: RegistrationMethod
    public init(method: RegistrationMethod) { self.method = method }

    public var name: AnalyticsEventName { "sign_up" }
    public var payload: AnalyticsPayload { ["method": method.analyticsValue] }
}
