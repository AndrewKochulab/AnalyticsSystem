import Foundation

// MARK: - Literal conformances
//
// These keep call sites as readable as the `[String: Any]` dictionary literals they
// replace — `["user_id": "abc", "count": 3]` still compiles — while being type-checked.

extension AnalyticsValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension AnalyticsValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension AnalyticsValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension AnalyticsValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension AnalyticsValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) { self = .null }
}

extension AnalyticsValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnalyticsValue...) { self = .array(elements) }
}

extension AnalyticsValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnalyticsValue)...) {
        self = .object(Dictionary(elements) { _, latest in latest })
    }
}
