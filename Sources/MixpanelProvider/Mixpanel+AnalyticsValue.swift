#if Mixpanel

import AnalyticsSystem
import Foundation
import Mixpanel

extension AnalyticsValue {
    /// Total by construction. v1 wrote `value as? MixpanelType`, so any value the SDK
    /// did not natively recognise was silently discarded before it left the device.
    var mixpanelValue: MixpanelType {
        switch self {
        case let .string(value): value
        case let .int(value): value
        case let .double(value): value
        case let .bool(value): value
        case let .date(value): value
        case let .url(value): value.absoluteString
        case .null: ""
        case let .array(values): values.map(\.mixpanelValue)
        case let .object(values): values.mapValues(\.mixpanelValue)
        }
    }
}

extension AnalyticsPayload {
    var mixpanelProperties: Properties {
        storage.mapValues(\.mixpanelValue)
    }
}

extension AnalyticsUser {
    /// Mixpanel's reserved People profile keys.
    var mixpanelProperties: Properties {
        var properties = traits.mixpanelProperties
        if let firstName { properties["$first_name"] = firstName }
        if let lastName { properties["$last_name"] = lastName }
        if let email { properties["$email"] = email }
        return properties
    }
}

#endif
