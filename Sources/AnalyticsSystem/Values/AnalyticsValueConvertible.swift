import Foundation

/// A type that can be represented as an ``AnalyticsValue``.
public protocol AnalyticsValueConvertible: Sendable {
    var analyticsValue: AnalyticsValue { get }
}

extension String: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .string(self) }
}

extension Int: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .int(self) }
}

extension Double: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .double(self) }
}

extension Float: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .double(Double(self)) }
}

extension Bool: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .bool(self) }
}

extension Date: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .date(self) }
}

extension URL: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .url(self) }
}

extension UUID: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .string(uuidString) }
}

extension AnalyticsValue: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { self }
}

extension Optional: AnalyticsValueConvertible where Wrapped: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue {
        self?.analyticsValue ?? .null
    }
}

extension Array: AnalyticsValueConvertible where Element: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .array(map(\.analyticsValue)) }
}

extension Dictionary: AnalyticsValueConvertible
where Key == String, Value: AnalyticsValueConvertible {
    public var analyticsValue: AnalyticsValue { .object(mapValues(\.analyticsValue)) }
}

/// Any `String`- or `Int`-backed enum becomes usable in a payload with no boilerplate.
public extension AnalyticsValueConvertible
where Self: RawRepresentable, Self.RawValue: AnalyticsValueConvertible {
    var analyticsValue: AnalyticsValue { rawValue.analyticsValue }
}
