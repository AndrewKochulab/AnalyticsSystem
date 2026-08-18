# Writing a Provider

Adapt any analytics destination in a few lines.

## Conform to AnalyticsTracker

Every requirement has a default no-op, so implement only what your destination
actually supports. There is deliberately no initializer requirement: nothing in this
library ever constructs a tracker, so a provider that needs an API key simply makes
that its only initializer.

```swift
struct MyTracker: AnalyticsTracker {
    let id: AnalyticsTrackerID = "my-tracker"
    private let apiKey: String

    init(apiKey: String) { self.apiKey = apiKey }

    func start(with context: AnalyticsStartContext) async {
        MySDK.configure(apiKey: apiKey)
    }

    func record(_ record: AnalyticsRecord) async {
        MySDK.log(record.name, record.payload.myValues)
    }
}
```

All requirements are `async`, so a conformer may be a `struct`, an `actor`, or a
`@MainActor` class — whichever matches the SDK's threading rules. The caller does not
care.

## Convert values totally

Write one exhaustive conversion from ``AnalyticsValue`` to your SDK's type. Making it
total is the point: a partial conversion is how values get dropped without anyone
noticing.

```swift
extension AnalyticsValue {
    var myValue: MySDKValue {
        switch self {
        case let .string(value): .text(value)
        case let .int(value): .number(Double(value))
        // …every case handled
        }
    }
}
```

If your SDK only accepts scalars, call ``AnalyticsPayload/flattened(separator:)`` first.

## Declare capabilities you have

Conform to ``CrashReportingTracker`` if your SDK can answer whether the previous run
crashed. The system consults only trackers that conform, so nothing has to stub it.

## Enforce your SDK's limits

If your SDK silently discards non-conforming events, express its rules as an
``AnalyticsRecordValidator`` and let callers opt in. Rejections are reported through
the diagnostics handler instead of disappearing.

```swift
try await analytics.register(FirebaseTracker(), validator: .firebase)
```
