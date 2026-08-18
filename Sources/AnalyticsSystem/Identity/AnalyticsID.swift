import Foundation

/// An opaque analytics identity — either the generated anonymous ID or a
/// caller-supplied user ID.
public struct AnalyticsID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func random() -> AnalyticsID {
        AnalyticsID(rawValue: UUID().uuidString)
    }
}

extension AnalyticsID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension AnalyticsID: CustomStringConvertible {
    public var description: String { rawValue }
}
