# Contributing

Thanks for taking the time. Bug reports, provider adapters and documentation fixes are
all welcome.

## Getting set up

Requires **Xcode 16.3+ / Swift 6.1+** — the package uses SwiftPM package traits.

```bash
git clone https://github.com/AndrewKochulab/AnalyticsSystem.git
cd AnalyticsSystem
swift build      # core only: resolves no third-party dependencies
swift test
```

## Working on a provider

Provider code is behind a trait *and*, in Facebook's case, behind `os(iOS)` — so a
plain `swift build` compiles none of it. Build the trait you are touching:

```bash
swift build --traits Firebase
```

and, because that still does not exercise iOS-only paths, build the integration
package before opening a PR:

```bash
cd IntegrationTests/ProviderBuild
xcodebuild build -scheme ProviderBuild -destination 'platform=iOS Simulator,name=iPhone 17'
```

That package exists because the pre-2.0 CI was green for years while compiling zero
provider code. Please keep it exercising whatever you add.

## Ground rules

- **No `fatalError`, `as!`, `try!` or force unwraps in `Sources/`.** SwiftLint enforces
  this. Each of them was a real crash in 1.x; model the failure in the type system.
- **Nothing may fail silently.** If a code path discards or rewrites an event, report an
  ``AnalyticsDiagnostic``. A dropped event is invisible otherwise.
- **Value conversions must be total.** A partial `switch` over `AnalyticsValue` is how
  data goes missing without anyone noticing.
- **The core stays dependency-free.** Anything that would appear in a default
  `swift package resolve` does not belong in `Package.swift`; CI asserts this.
- **Swift 6 language mode, no `@unchecked Sendable`** outside the one documented lock.

## Tests

Use Swift Testing. Prefer `await system.flush()` as an exact barrier over sleeping.
Bug fixes get a regression test whose comment names the bug it prevents.

```bash
swift test
swiftlint lint --strict
```
