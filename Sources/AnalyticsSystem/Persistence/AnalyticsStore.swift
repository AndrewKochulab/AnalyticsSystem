import Foundation

/// Minimal key/value persistence used for the anonymous identity.
///
/// Injected rather than hard-wired, which is what makes identity behaviour testable
/// without touching the real `UserDefaults`.
public protocol AnalyticsStore: Sendable {
    func string(forKey key: String) -> String?

    /// Stores `value`, or **removes** the key when `value` is `nil`.
    func setString(_ value: String?, forKey key: String)
}
