#if Bugsnag

import AnalyticsSystem
import Foundation

extension AnalyticsValue {
    var bugsnagValue: Any {
        switch self {
        case let .string(value): value
        case let .int(value): NSNumber(value: value)
        case let .double(value): NSNumber(value: value)
        case let .bool(value): NSNumber(value: value)
        case let .date(value): ISO8601DateFormatter().string(from: value)
        case let .url(value): value.absoluteString
        case .null: NSNull()
        case let .array(values): values.map(\.bugsnagValue)
        case let .object(values): values.mapValues(\.bugsnagValue)
        }
    }
}

extension AnalyticsPayload {
    /// Bugsnag breadcrumb metadata accepts nested containers, so no flattening.
    var bugsnagMetadata: [String: Any] {
        storage.mapValues(\.bugsnagValue)
    }
}

#endif
