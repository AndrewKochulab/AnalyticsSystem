import Foundation

/// Stable, explicit identity for a registered tracker.
///
/// v1 keyed its registry on `String(describing: tracker)`, which varies with generic
/// parameters and cannot distinguish two instances of the same provider. An explicit
/// ID makes registration collisions detectable and removal deterministic, and lets a
/// single app register, say, two Mixpanel projects side by side.
public struct AnalyticsTrackerID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension AnalyticsTrackerID {
    static let console: Self = "console"
    static let firebase: Self = "firebase"
    static let facebook: Self = "facebook"
    static let mixpanel: Self = "mixpanel"
    static let bugsnag: Self = "bugsnag"
}

extension AnalyticsTrackerID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension AnalyticsTrackerID: CustomStringConvertible {
    public var description: String { rawValue }
}
