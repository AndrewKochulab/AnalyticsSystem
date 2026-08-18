# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 2.x | ✅ |
| 1.x | ❌ — unbuildable on current toolchains; please upgrade |

## Reporting a vulnerability

Please **do not open a public issue**. Report privately via
[GitHub Security Advisories](https://github.com/AndrewKochulab/AnalyticsSystem/security/advisories/new),
or email andrew.kochulab@gmail.com.

Expect an acknowledgement within a few days.

## Scope

This library forwards data you give it to analytics providers you choose. Worth knowing:

- **It does not collect anything on its own.** Every attribute is one you passed to it.
- **An anonymous identifier is generated and stored** in `UserDefaults` (or a store you
  inject) and sent to providers to correlate a session. `logOut()` rotates it, so
  post-logout activity is not linked to the previous user.
- **`AnalyticsUser` fields go to providers verbatim.** Do not put secrets, tokens or
  data you are not entitled to share into events or user traits.
- **Vendor SDKs are the larger surface.** Report issues in Firebase, Facebook, Mixpanel
  or Bugsnag to those projects; this package only adapts them.
