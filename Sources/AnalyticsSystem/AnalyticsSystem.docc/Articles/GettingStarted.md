# Getting Started

Wire up providers, describe your events, and track them.

## Describe an event

An event is a plain `Sendable` value that knows its own name and attributes.

```swift
enum RegistrationMethod: String, AnalyticsValueConvertible {
    case email = "Email"
    case facebook = "Facebook"
}

struct SignUpEvent: AnalyticsEvent {
    static let category: AnalyticsEventCategory = .authentication

    let method: RegistrationMethod

    var name: AnalyticsEventName { "sign_up" }
    var payload: AnalyticsPayload { ["method": method.analyticsValue] }
}
```

Attributes are ``AnalyticsValue``, not `Any`. That is what lets an event cross
concurrency domains, and it turns "the SDK did not recognise that value" from silent
data loss into an explicit, testable conversion.

## Register providers and start

```swift
let analytics = AnalyticsSystem()

try await analytics.register(ConsoleTracker())
try await analytics.register(BugsnagTracker(apiKey: "key"))

await analytics.setGlobalProperties(["app_version": "2.1.0"])
await analytics.start()
```

Global properties are merged into every record. Event attributes win on key conflict,
so an event can always override one.

## Track

```swift
analytics.track(SignUpEvent(method: .email))
```

## Send only some events to a provider

Filters are values, and they compose:

```swift
try await analytics.register(
    FacebookTracker(),
    filter: .categories(.authentication) || .only(PurchaseEvent.self)
)
```

## Render an event differently for one provider

Layer mappers rather than subclassing anything:

```swift
let facebookMapper = AnalyticsEventMapper()
    .mapping(for: SignUpEvent.self) { event in
        AnalyticsRecord(
            name: "fb_mobile_complete_registration",
            attributes: ["fb_registration_method": event.method]
        )
    }
    .overriding(common)
```

Returning `nil`, or using ``AnalyticsEventMapper/ignoring(_:)``, drops that event for
that provider only.

## See what you are losing

Analytics failures are invisible by default: a dropped event looks exactly like one
that was never sent. Attach a diagnostics handler and they become observable.

```swift
let analytics = AnalyticsSystem(
    configuration: .init(
        diagnostics: { diagnostic in
            logger.warning("analytics: \(diagnostic)")
        }
    )
)
```

## Flush before the app goes away

``AnalyticsSystem/flush()`` drains this library's own queue.
``AnalyticsSystem/flushProviders()`` asks each vendor SDK to send what it has batched —
that is the one you want when backgrounding.
