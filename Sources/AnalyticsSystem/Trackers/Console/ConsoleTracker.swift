import Foundation

/// Logs analytics activity instead of sending it anywhere.
///
/// Useful in debug builds and as a worked example of the ``AnalyticsTracker``
/// protocol: a stateless `struct`, no base class, no API token, nothing to stub.
public struct ConsoleTracker: AnalyticsTracker {
    public let id: AnalyticsTrackerID
    private let sink: any AnalyticsLogSink
    private let prefix: String

    public init(
        id: AnalyticsTrackerID = .console,
        sink: any AnalyticsLogSink = OSLogSink(),
        prefix: String = "📱 Analytics"
    ) {
        self.id = id
        self.sink = sink
        self.prefix = prefix
    }

    public func start(with context: AnalyticsStartContext) async {
        let suffix = context.attributes.isEmpty ? "" : " \(context.attributes)"
        sink.write("\(prefix) started\(suffix)")
    }

    public func setEnabled(_ isEnabled: Bool) async {
        sink.write("\(prefix) collection \(isEnabled ? "enabled" : "disabled")")
    }

    public func identify(anonymousID: AnalyticsID) async {
        sink.write("\(prefix) anonymous id: \(anonymousID)")
    }

    public func logIn(user: AnalyticsUser) async {
        sink.write("\(prefix) log in: \(user.id)")
    }

    public func logOut() async {
        sink.write("\(prefix) log out")
    }

    public func record(_ record: AnalyticsRecord) async {
        sink.write("\(prefix) event: \(record)")
    }
}
