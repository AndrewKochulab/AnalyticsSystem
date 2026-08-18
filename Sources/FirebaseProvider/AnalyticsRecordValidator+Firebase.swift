#if Firebase && (os(iOS) || os(macOS) || os(tvOS) || os(visionOS))

import AnalyticsSystem
import Foundation

public extension AnalyticsRecordValidator {
    /// Firebase Analytics' documented limits, enforced locally.
    ///
    /// Firebase discards a non-conforming event server-side and reports nothing, so
    /// without this the data simply never appears and there is nothing to debug.
    /// Names and parameter keys are sanitized where that is unambiguous; anything
    /// that cannot be repaired safely is rejected with a reason.
    ///
    /// Limits: event and parameter names ≤ 40 characters, alphanumeric or underscore,
    /// beginning with a letter; at most 25 parameters; string values ≤ 100 characters;
    /// the `firebase_`, `google_` and `ga_` prefixes are reserved.
    static let firebase = AnalyticsRecordValidator { record in
        let name = sanitizedIdentifier(record.name)

        guard let first = name.first, first.isLetter else {
            return .reject(reason: "Firebase event names must begin with a letter: '\(record.name)'")
        }
        for reserved in reservedPrefixes where name.lowercased().hasPrefix(reserved) {
            return .reject(reason: "'\(reserved)' is a reserved Firebase prefix: '\(record.name)'")
        }
        guard record.payload.count <= maximumParameterCount else {
            return .reject(
                reason: "Firebase allows \(maximumParameterCount) parameters, got \(record.payload.count)"
            )
        }

        var sanitized = AnalyticsPayload()
        for (key, value) in record.payload {
            let key = String(sanitizedIdentifier(key).prefix(maximumNameLength))
            guard let first = key.first, first.isLetter else { continue }
            sanitized[key] = truncated(value)
        }

        return .accept(
            AnalyticsRecord(name: String(name.prefix(maximumNameLength)), payload: sanitized)
        )
    }

    private static let maximumNameLength = 40
    private static let maximumValueLength = 100
    private static let maximumParameterCount = 25
    private static let reservedPrefixes = ["firebase_", "google_", "ga_"]

    /// Replaces every character Firebase disallows with an underscore.
    private static func sanitizedIdentifier(_ value: String) -> String {
        String(value.map { $0.isLetter || $0.isNumber || $0 == "_" ? $0 : "_" })
    }

    private static func truncated(_ value: AnalyticsValue) -> AnalyticsValue {
        guard case let .string(string) = value, string.count > maximumValueLength else {
            return value
        }
        return .string(String(string.prefix(maximumValueLength)))
    }
}

#endif
