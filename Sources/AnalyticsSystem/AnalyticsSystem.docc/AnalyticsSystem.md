# ``AnalyticsSystem``

Fan analytics events out to any number of providers behind one small, `Sendable` API.

## Overview

The core carries no third-party dependencies. Providers are opt-in SwiftPM package
traits, so a default install resolves nothing at all — not Firebase, not its
transitive tree. What you do not enable is never even cloned.

```swift
let analytics = AnalyticsSystem()

try await analytics.register(ConsoleTracker())
try await analytics.register(MixpanelTracker(apiToken: "token"))

await analytics.start()
analytics.track(SignUpEvent(method: .email))
```

``AnalyticsSystem/track(_:)`` is synchronous and callable from any isolation domain —
a fire-and-forget logging call should not put a suspension point in a UI path. Every
operation still passes through one serial queue, which is what guarantees that a
``AnalyticsSystem/logIn(user:)`` reaches providers before an event tracked right after it.

### Call start() before you rely on delivery

Events tracked before ``AnalyticsSystem/start(with:)`` are held and replayed once it
completes — see ``AnalyticsStartupBuffer``. Without that, launch-time events would
either be lost outright or handed to a provider whose SDK had not been initialised.

## Topics

### Essentials

- ``AnalyticsSystem``
- ``AnalyticsEvent``
- ``AnalyticsTracker``
- <doc:GettingStarted>

### Describing events

- ``AnalyticsEventName``
- ``AnalyticsEventCategory``
- ``AnalyticsPayload``
- ``AnalyticsValue``
- ``AnalyticsValueConvertible``
- ``AnalyticsRecord``

### Routing

- ``AnalyticsEventMapper``
- ``AnalyticsEventFilter``
- ``AnalyticsRecordValidator``
- ``AnalyticsTrackerID``
- <doc:WritingAProvider>

### Identity

- ``AnalyticsUser``
- ``AnalyticsID``

### Configuration and observability

- ``AnalyticsStartupBuffer``
- ``AnalyticsDiagnostic``
- ``AnalyticsDiagnosticHandler``
- ``AnalyticsStore``
- ``UserDefaultsAnalyticsStore``
- ``InMemoryAnalyticsStore``

### Built-in trackers

- ``ConsoleTracker``
- ``AnalyticsLogSink``
- ``OSLogSink``
- ``StandardOutputLogSink``

### Capabilities

- ``CrashReportingTracker``
- ``AnalyticsStartContext``
- ``AnalyticsError``
