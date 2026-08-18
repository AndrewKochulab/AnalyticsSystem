#if Firebase && (os(iOS) || os(macOS) || os(tvOS) || os(visionOS))

import AnalyticsSystem
import Foundation

extension AnalyticsValue {
    /// Firebase Analytics accepts only `NSString` and `NSNumber` parameters, so the
    /// conversion is total by construction: anything non-scalar is rendered as text
    /// rather than silently dropped.
    var firebaseParameterValue: Any {
        switch self {
        case let .string(value): value
        case let .int(value): NSNumber(value: value)
        case let .double(value): NSNumber(value: value)
        case let .bool(value): NSNumber(value: value)
        case let .date(value): ISO8601DateFormatter().string(from: value)
        case let .url(value): value.absoluteString
        case .null: ""
        case .array, .object: description
        }
    }

    /// User properties must be strings.
    var firebaseUserPropertyValue: String {
        if case let .string(value) = self { return value }
        return description
    }
}

extension AnalyticsPayload {
    /// Flattens first, because Firebase rejects nested containers outright.
    var firebaseParameters: [String: Any] {
        flattened().storage.mapValues(\.firebaseParameterValue)
    }
}

#endif
