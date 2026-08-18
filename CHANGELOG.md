# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-08-18

A full rewrite. 2.0.0 is a breaking release; see [MIGRATION.md](MIGRATION.md).
**1.0.0 is untouched** — existing consumers stay on that tag until they choose to move.

### Fixed

- **Force cast in the public API.** `FactoryAnalyticsTracker` recovered an event's
  concrete type with `event as! Event`, commented "safe operation". It was not: any
  factory asked for an event type it was not written against crashed the app. Events
  now carry their type in a closure captured at the call site, so nothing on the event
  path casts at all.
- **Two `fatalError` initializers reachable from public API.** `MixpanelTracker` and
  `BugsnagTracker` each declared `required init(eventsFactory:) { fatalError(...) }` to
  satisfy an inherited requirement, making `AnalyticsTrackersControl.addTracker(_:with:)`
  a guaranteed runtime crash for those providers. The library no longer constructs
  trackers, so the requirement — and the trap — are gone.
- **Mixpanel identity leaked across users.** `logOut` cleared timed events and super
  properties but never called `reset()`, so the distinct ID survived and the next user
  on the device was silently correlated with the previous one.
- **Unstable registry identity.** Trackers were keyed on `String(describing:)`, which
  varies with generic parameters and cannot distinguish two instances of one provider.
  Replaced by an explicit `AnalyticsTrackerID`.
- **No thread safety.** The tracker dictionary and the enabled flag were mutated from
  arbitrary threads without synchronisation. State now lives behind an actor.
- **`UIApplication` leaked into cross-platform code.** The tracker protocol declared
  `typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]` guarded on
  `canImport(UIKit)` while the import was guarded on `os(iOS)`. Launch options now go
  straight to `FacebookTracker.handleLaunch(options:)`.
- **Clearing the anonymous ID did not clear it.** The `@UserDefault` wrapper stored a
  null on assignment of `nil` instead of removing the key, and called the long-deprecated
  `synchronize()`.
- **Bugsnag could never receive an event** — its availability check was hardcoded `false`.
- **Firebase never reported crashes** — `appDidCrashLastLaunch()` returned `false`
  unconditionally, though Crashlytics answers this.
- **Console output was bracketed.** `ConsoleTracker.print` shadowed `Swift.print` and
  forwarded the variadic array, rendering every line as `["…"]`.
- **CI proved nothing.** It ran `swift build` on macOS while every provider was
  `#if os(iOS)`-gated, so no adapter body was ever compiled. A dedicated job now builds
  all four against their real SDKs for iOS.
- **The package did not build.** Firebase and Facebook were pinned to `.branch("master")`,
  the deployment target was iOS 10, and the adapters called SDK APIs removed years ago
  (`AppEvents` statics, dropped in Facebook SDK v12).

### Added

- **Package traits** for each provider. A default install resolves **zero** third-party
  dependencies — previously every consumer pulled Firebase's entire transitive tree
  (gRPC, BoringSSL, abseil, leveldb, nanopb, Promises, GTMSessionFetcher) just to use
  the console tracker.
- **Swift 6 language mode** across every target, with no `@unchecked Sendable` anywhere
  except one documented mutex box.
- `AnalyticsValue` / `AnalyticsPayload` — a closed, `Sendable` value space replacing
  `[String: Any]`, with total per-provider conversions.
- `AnalyticsEventMapper` — per-event-type rendering by composition, replacing the
  factory base class and its subclassing pattern.
- `AnalyticsEventFilter` — composable, immutable admission rules replacing the mutable
  `isEventAvailable` closure.
- `CrashReportingTracker` — an opt-in capability, so providers no longer stub methods
  they cannot implement.
- `flush()` — an exact barrier that makes analytics behaviour testable without sleeps.
- Guaranteed ordering between lifecycle calls and events.
- `OSLogSink` / injectable `AnalyticsLogSink` for console output.
- visionOS support.
- **57 tests** across 11 suites, using Swift Testing. The v1 suite contained one test
  whose only assertion was commented out.
- `MIGRATION.md`, this changelog, a SwiftLint configuration, and a CI pipeline covering
  core, five platforms, all four providers, lint, and podspec validation.

### Changed

- Minimum platforms are now iOS 15, macOS 12, tvOS 15, watchOS 8, visionOS 1
  (from iOS 10 / macOS 10.12 / tvOS 10 / watchOS 6). Firebase 12 sets the iOS 15 floor.
- `swift-tools-version` 5.3 → 6.1; the podspec's Swift version is now consistent with it.
- Provider SDKs pinned to real releases: Firebase 12.17, Facebook 18.1, Mixpanel 6.5,
  Bugsnag 6.37.
- `AnalyticsUser` is a struct rather than a protocol.
- `track(_:)` is synchronous and callable from any isolation domain; lifecycle methods
  are `async`.
- The CocoaPods spec exposes **all four** providers again — v1 had quietly deleted the
  Firebase and Mixpanel subspecs, so CocoaPods and SwiftPM shipped different sets.

### Removed

- `FactoryAnalyticsTracker`, `AnalyticsTrackersControl`, `AnalyticsEventOperation`,
  `AnalyticsEventBuilder`, `AnalyticsEventType`, `AnalyticsSystemPersistence`, the
  `@UserDefault` wrapper, and the `AnalyticsUserAttributes` typealias.
- The `DECIDE` compilation define, a Mixpanel-internal flag referenced by nothing.
- `Tests/LinuxMain.swift` and `XCTestManifests.swift`, obsolete since Swift 5.4.

## [1.0.0] - 2020-11-19

Initial release.

[2.0.0]: https://github.com/AndrewKochulab/AnalyticsSystem/compare/1.0.0...2.0.0
[1.0.0]: https://github.com/AndrewKochulab/AnalyticsSystem/releases/tag/1.0.0
