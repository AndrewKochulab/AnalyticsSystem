import Foundation

/// Decides whether a record may be sent to a provider, and optionally rewrites it.
///
/// Vendor SDKs enforce limits that they do not report back: Firebase, for instance,
/// silently discards an event whose name exceeds 40 characters. Without a validator
/// the data simply never appears, with nothing to debug. Running the provider's own
/// rules locally turns that into a diagnostic at the call site.
public struct AnalyticsRecordValidator: Sendable {
    public enum Outcome: Sendable {
        /// Send this record. It may differ from the input if it was sanitized.
        case accept(AnalyticsRecord)
        /// Do not send; the reason is reported as a diagnostic.
        case reject(reason: String)
    }

    let validate: @Sendable (AnalyticsRecord) -> Outcome

    public init(_ validate: @escaping @Sendable (AnalyticsRecord) -> Outcome) {
        self.validate = validate
    }

    public func callAsFunction(_ record: AnalyticsRecord) -> Outcome {
        validate(record)
    }

    /// Accepts anything with a non-empty name — the baseline every provider shares.
    public static let `default` = AnalyticsRecordValidator { record in
        record.name.isEmpty
            ? .reject(reason: "event name is empty")
            : .accept(record)
    }

    /// Accepts everything, including unnamed records.
    public static let permissive = AnalyticsRecordValidator { .accept($0) }

    /// Runs `self`, then feeds an accepted record through `other`.
    public func combined(with other: AnalyticsRecordValidator) -> Self {
        AnalyticsRecordValidator { record in
            switch validate(record) {
            case let .accept(accepted): other.validate(accepted)
            case let .reject(reason): .reject(reason: reason)
            }
        }
    }
}
