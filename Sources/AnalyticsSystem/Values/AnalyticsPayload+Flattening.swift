import Foundation

public extension AnalyticsPayload {
    /// Collapses nested `.object` and `.array` values into scalar entries with compound keys.
    ///
    /// Several vendor SDKs — Firebase Analytics most notably — accept only scalar
    /// parameters. Flattening makes that constraint explicit and testable rather than
    /// discovering it as silently missing data in a dashboard.
    ///
    /// ```
    /// ["user": .object(["id": "7"])]   ->  ["user_id": "7"]
    /// ["tags": .array(["a", "b"])]     ->  ["tags_0": "a", "tags_1": "b"]
    /// ```
    func flattened(separator: String = "_") -> AnalyticsPayload {
        var result: [String: AnalyticsValue] = [:]
        for (key, value) in storage {
            Self.flatten(value: value, into: &result, prefix: key, separator: separator)
        }
        return AnalyticsPayload(result)
    }

    private static func flatten(
        value: AnalyticsValue,
        into result: inout [String: AnalyticsValue],
        prefix: String,
        separator: String
    ) {
        switch value {
        case let .object(nested):
            for (key, nestedValue) in nested {
                flatten(
                    value: nestedValue,
                    into: &result,
                    prefix: "\(prefix)\(separator)\(key)",
                    separator: separator
                )
            }
        case let .array(elements):
            for (index, element) in elements.enumerated() {
                flatten(
                    value: element,
                    into: &result,
                    prefix: "\(prefix)\(separator)\(index)",
                    separator: separator
                )
            }
        default:
            result[prefix] = value
        }
    }
}
