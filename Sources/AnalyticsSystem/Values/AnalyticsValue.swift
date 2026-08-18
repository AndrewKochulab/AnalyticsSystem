import Foundation

/// A closed, `Sendable` representation of every value an analytics payload may carry.
///
/// This type exists because `[String: Any]` cannot cross concurrency domains, and
/// because every provider needs a typed conversion anyway. Making the value space
/// explicit turns what used to be silent data loss — a value the vendor SDK did not
/// recognise was simply dropped — into a total, testable conversion per provider.
public enum AnalyticsValue: Hashable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case url(URL)
    case null
    indirect case array([AnalyticsValue])
    indirect case object([String: AnalyticsValue])
}

// MARK: - Convenience accessors

public extension AnalyticsValue {
    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    var intValue: Int? {
        guard case let .int(value) = self else { return nil }
        return value
    }

    var doubleValue: Double? {
        switch self {
        case let .double(value): value
        case let .int(value): Double(value)
        default: nil
        }
    }

    var boolValue: Bool? {
        guard case let .bool(value) = self else { return nil }
        return value
    }

    var isNull: Bool { self == .null }
}

// MARK: - CustomStringConvertible

extension AnalyticsValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .string(value): value
        case let .int(value): String(value)
        case let .double(value): String(value)
        case let .bool(value): String(value)
        case let .date(value): ISO8601DateFormatter().string(from: value)
        case let .url(value): value.absoluteString
        case .null: "null"
        case let .array(values): "[\(values.map(\.description).joined(separator: ", "))]"
        case let .object(values):
            "{\(values.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: ", "))}"
        }
    }
}
