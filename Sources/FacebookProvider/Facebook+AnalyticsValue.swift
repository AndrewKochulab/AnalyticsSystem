#if Facebook && os(iOS)

import AnalyticsSystem
import FBSDKCoreKit
import Foundation

extension AnalyticsValue {
    /// App Events parameters accept only strings and numbers.
    var facebookParameterValue: Any {
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
}

extension AnalyticsPayload {
    var facebookParameters: [AppEvents.ParameterName: Any] {
        var parameters: [AppEvents.ParameterName: Any] = [:]
        for (key, value) in flattened().storage {
            parameters[AppEvents.ParameterName(key)] = value.facebookParameterValue
        }
        return parameters
    }
}

#endif
