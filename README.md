# AnalyticsSystem

[![CI](https://github.com/AndrewKochulab/AnalyticsSystem/actions/workflows/ci.yml/badge.svg)](https://github.com/AndrewKochulab/AnalyticsSystem/actions/workflows/ci.yml)
[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2015%20%7C%20macOS%2012%20%7C%20tvOS%2015%20%7C%20watchOS%208%20%7C%20visionOS%201-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Fan analytics events out to any number of providers behind one small API.

- **The core has zero third-party dependencies.** Providers are opt-in
  [package traits](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0450-swiftpm-package-traits.md),
  so a default install resolves *nothing* — not Firebase, not its transitive tree.
- **Built for Swift 6 strict concurrency.** No `@unchecked Sendable`, no locks in your code, no main-thread work.
- **`track` is synchronous.** Call it from a view model, a background task, anywhere. No `await`.
- **Ordering is guaranteed.** A `logIn` followed by a `track` reaches every provider in that order.

## Providers

| Provider | Trait | Platforms | Crash reporting |
|---|---|---|---|
| Firebase Analytics + Crashlytics | `Firebase` | iOS, macOS, tvOS, visionOS | ✅ |
| Facebook App Events | `Facebook` | iOS | — |
| Mixpanel | `Mixpanel` | all | — |
| Bugsnag | `Bugsnag` | all | ✅ |
| Console / `os.Logger` | *(built in)* | all | — |

## Installation

### Swift Package Manager

Core only — resolves no third-party packages at all:

```swift
.package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git", from: "2.0.0")
```

Opt in to the providers you actually ship. Anything you leave out is never even cloned:

```swift
.package(
    url: "https://github.com/AndrewKochulab/AnalyticsSystem.git",
    from: "2.0.0",
    traits: ["Firebase", "Mixpanel"]
)
```

> **Requires Swift 6.1 / Xcode 16.3 or newer** on the consuming side — package traits are
> what make the zero-dependency core possible. If you are on an older toolchain, stay on
> [1.0.0](https://github.com/AndrewKochulab/AnalyticsSystem/tree/1.0.0).

### CocoaPods

```ruby
pod 'AnalyticsSystem'                # Core only
pod 'AnalyticsSystem/Firebase'       # + Firebase
pod 'AnalyticsSystem/Facebook'
pod 'AnalyticsSystem/Mixpanel'
pod 'AnalyticsSystem/Bugsnag'
```

## Usage

### 1. Describe your events

An event is a plain `Sendable` value that knows its own name and attributes.

```swift
import AnalyticsSystem

enum RegistrationMethod: String, AnalyticsValueConvertible {
    case email = "Email"
    case facebook = "Facebook"
}

struct SignUpEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .authentication

    let userID: String
    let method: RegistrationMethod

    var name: AnalyticsEventName { "sign_up" }
    var payload: AnalyticsPayload {
        ["user_id": .string(userID), "method": method.analyticsValue]
    }
}
```

`AnalyticsPayload` is a typed bag of `AnalyticsValue`, not `[String: Any]` — which is
what lets events cross concurrency domains, and what turns "the SDK didn't recognise
that value" from silent data loss into an explicit, tested conversion.

### 2. Register providers

```swift
let analytics = AnalyticsSystem()

try await analytics.register(ConsoleTracker())
try await analytics.register(MixpanelTracker(apiToken: "your_token"))
try await analytics.register(BugsnagTracker(apiKey: "your_key"))

await analytics.start()
```

### 3. Track

```swift
analytics.track(SignUpEvent(userID: "user-1", method: .email))
```

That's it — synchronous, non-throwing, callable from any isolation domain.

### Sending only some events to a provider

Filters are values, and they compose:

```swift
try await analytics.register(
    FacebookTracker(),
    filter: .categories(.authentication) || .only(PurchaseEvent.self)
)
```

### Rendering an event differently for one provider

Override per event type by composing mappers. No subclassing:

```swift
let common = AnalyticsEventMapper()

let facebookMapper = AnalyticsEventMapper()
    .mapping(for: SignUpEvent.self) { event in
        AnalyticsRecord(
            name: "fb_mobile_complete_registration",
            attributes: ["fb_registration_method": event.method]
        )
    }
    .overriding(common)

try await analytics.register(FacebookTracker(), mapper: facebookMapper)
```

Returning `nil` from a mapping — or using `.ignoring(SomeEvent.self)` — drops that
event for that provider only.

### Identity

```swift
await analytics.logIn(
    user: AnalyticsUser(id: "user-1", firstName: "Ada", email: "ada@example.com")
)

await analytics.logOut()   // resets every provider and rotates the anonymous ID
```

### Crash reporting

```swift
if await analytics.didCrashOnLastLaunch() {
    // Firebase and Bugsnag both answer this.
}
```

### Facebook and UIKit launch options

The core never touches UIKit. The one provider that needs launch options takes them
directly from your app delegate:

```swift
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    facebookTracker.handleLaunch(options: options)
    Task { await analytics.start() }
    return true
}
```

### Writing your own provider

Implement only what your destination supports — every requirement has a default no-op:

```swift
struct MyTracker: AnalyticsTracker {
    let id: AnalyticsTrackerID = "my-tracker"

    func record(_ record: AnalyticsRecord) async {
        // send record.name and record.payload
    }
}
```

Add `CrashReportingTracker` if it also observes crashes.

## Testing

Inject an in-memory store and a deterministic ID generator, and use `flush()` as an
exact barrier instead of sleeping:

```swift
let analytics = AnalyticsSystem(
    configuration: .init(
        store: InMemoryAnalyticsStore(),
        idGenerator: { AnalyticsID(rawValue: "fixed") }
    )
)

analytics.track(SignUpEvent(userID: "1", method: .email))
await analytics.flush()   // returns only once every provider has been called
```

## Migrating from 1.0.0

2.0.0 is a deliberate breaking release — see [MIGRATION.md](MIGRATION.md) for a
symbol-by-symbol map. 1.0.0 is untouched and remains installable.

## Contributing

Bug reports and pull requests are welcome. `swift test` should be green and
`swiftlint lint --strict` clean before you open one.

⭐️ If you find this useful, star the repo.

## License

MIT. See [LICENSE](LICENSE).
