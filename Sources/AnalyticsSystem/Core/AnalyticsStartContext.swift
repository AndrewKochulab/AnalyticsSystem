import Foundation

/// Launch-time context handed to trackers on ``AnalyticsSystem/start(with:)``.
///
/// Deliberately free of UIKit. v1 declared
/// `typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]` on the
/// cross-platform tracker protocol, which both leaked a UIKit type into tvOS/watchOS
/// builds and made the protocol impossible to make `Sendable`.
///
/// The one provider that needs real launch options — Facebook — accepts them
/// directly via `FacebookTracker.handleLaunch(options:)`, called from the app's
/// `AppDelegate`. That keeps this package entirely free of unsound `Sendable`
/// conformances.
public struct AnalyticsStartContext: Hashable, Sendable {
    /// Provider-agnostic launch metadata.
    public var attributes: AnalyticsPayload

    public static let empty = AnalyticsStartContext()

    public init(attributes: AnalyticsPayload = .empty) {
        self.attributes = attributes
    }
}
