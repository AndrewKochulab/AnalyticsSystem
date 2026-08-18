# Migrating from 1.0.0 to 2.0.0

2.0.0 is a clean break, with no deprecation shims. Nothing about 1.0.0 changes — if
you are not ready, stay on that tag.

**Before you start:** 2.0.0 requires **Swift 6.1 / Xcode 16.3+** and **iOS 15+**
(macOS 12, tvOS 15, watchOS 8, visionOS 1). Firebase 12 sets the iOS floor.

## 1. Update the dependency and opt in to providers

Providers are now [package traits](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0450-swiftpm-package-traits.md).
If you do not list a trait, that SDK is never resolved or cloned.

```diff
- .package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git", from: "1.0.0")
+ .package(
+     url: "https://github.com/AndrewKochulab/AnalyticsSystem.git",
+     from: "2.0.0",
+     traits: ["Firebase", "Mixpanel"]
+ )
```

CocoaPods users keep using subspecs — and Firebase and Mixpanel are available again,
having been dropped from the v1 podspec.

## 2. Symbol map

| 1.0.0 | 2.0.0 | Notes |
|---|---|---|
| `AnalyticsTrackersControl` | `AnalyticsSystem.register(_:mapper:filter:)` | The registry is internal now. |
| `cfg.addTracker(_:)` | `try await analytics.register(_:)` | `async throws`. |
| `cfg.removeTracker(_:)` | `try await analytics.unregister(_:)` | Takes an `AnalyticsTrackerID`. |
| `configureTrackers(with:configuration:)` | `register(...)` then `await start()` | No configuration closure. |
| `initialize()` | `await start(with:)` | |
| `FactoryAnalyticsTracker<F>` | `AnalyticsTracker` protocol | Composition, not a base class. |
| `AnalyticsTrackerFactory` | `AnalyticsEventMapper` | A value, not a protocol to subclass. |
| `AnalyticsEventBuilder` | `AnalyticsRecord` | A struct; genuinely `CustomStringConvertible`. |
| `AnalyticsEventType` (OptionSet, no cases) | `AnalyticsEventCategory` | Ships real members. |
| `tracker.isEventAvailable = { … }` | `filter:` at registration | Immutable and composable. |
| `AnalyticsUser` (protocol) | `AnalyticsUser` (struct) | Add extra fields via `traits`. |
| `AnalyticsID` (`typealias String`) | `AnalyticsID` (struct) | |
| `[String: Any]` attributes | `AnalyticsPayload` / `AnalyticsValue` | Typed and `Sendable`. |
| `canObserveAppCrashes()` + `appDidCrashLastLaunch()` | `CrashReportingTracker` | Opt-in capability. |
| `appDidCrashLastLaunch()` on the facade | `await didCrashOnLastLaunch()` | |
| `logOut(user:)` | `await logOut()` | No user argument. |
| `AnalyticsUserAttributes` | *(removed)* | Was never used. |

## 3. Events

Events now carry their own name, and attributes are typed.

```diff
  struct SignUpEvent: AnalyticsEvent {
      let userId: String
      let method: RegistrationEventMethod
-     var type: AnalyticsEventType { .signUp }
+     static let category: AnalyticsEventCategory = .authentication
+
+     var name: AnalyticsEventName { "sign_up" }
+     var payload: AnalyticsPayload {
+         ["user_id": .string(userId), "method": method.analyticsValue]
+     }
  }
```

Make any `RawRepresentable` enum usable in a payload by conforming it to
`AnalyticsValueConvertible` — no other work required:

```swift
enum RegistrationEventMethod: String, AnalyticsValueConvertible {
    case email = "Email"
}
```

## 4. Per-provider rendering: subclassing becomes composition

v1 asked you to subclass a factory. v2 layers mappers, which is also what removes the
`as!` that made the old approach crash-prone.

```diff
- final class FacebookTrackerEventsFactory: AnalyticsTrackerEventsFactory {
-     override func signUpEventBuilder(event: SignUpEvent) -> AnalyticsEventBuilder {
-         .init(name: "fb_mobile_complete_registration", attributes: [...])
-     }
- }
+ let facebookMapper = AnalyticsEventMapper()
+     .mapping(for: SignUpEvent.self) { event in
+         AnalyticsRecord(
+             name: "fb_mobile_complete_registration",
+             attributes: ["fb_registration_method": event.method]
+         )
+     }
+     .overriding(commonMapper)
```

## 5. Setup

```diff
- let analyticsSystem = AnalyticsSystem()
- try analyticsSystem.configureTrackers { cfg in
-     let factory = AnalyticsTrackerEventsFactory()
-     try cfg.addTracker(MixpanelTracker(apiToken: "token", eventsFactory: factory))
-     let fb = FacebookTracker(eventsFactory: FacebookTrackerEventsFactory())
-     fb.isEventAvailable = { $0 == .signUp }
-     try cfg.addTracker(fb)
- }
- analyticsSystem.initialize()
+ let analytics = AnalyticsSystem()
+ try await analytics.register(MixpanelTracker(apiToken: "token"))
+ try await analytics.register(
+     FacebookTracker(),
+     mapper: facebookMapper,
+     filter: .only(SignUpEvent.self)
+ )
+ await analytics.start()
```

`track` is unchanged in spirit — still synchronous, still callable from anywhere:

```swift
analytics.track(SignUpEvent(userId: "1", method: .email))
```

## 6. Facebook launch options

v1 routed `[UIApplication.LaunchOptionsKey: Any]` through the cross-platform core.
v2 does not; hand them to the provider directly.

```diff
- try analyticsSystem.configureTrackers(with: launchOptions) { … }
+ facebookTracker.handleLaunch(options: launchOptions)
+ Task { await analytics.start() }
```

## 7. Behaviour changes worth knowing

- **Mixpanel `logOut` now calls `reset()`.** v1 did not, so the distinct ID survived
  log out. Expect a new distinct ID per user — this is the correct behaviour, but it
  will show up as a discontinuity in your Mixpanel data at the point you upgrade.
- **Bugsnag now receives events** as breadcrumbs. v1 silently dropped them all. To keep
  the old behaviour, register it with `filter: .none`.
- **Firebase now answers `didCrashOnLastLaunch()`** instead of always returning `false`.
- **Log out rotates the anonymous ID**, so post-logout activity is not correlated with
  the previous user.
