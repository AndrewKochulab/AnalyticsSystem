import Foundation
import os

/// Destination for ``ConsoleTracker`` output.
///
/// Injected so console behaviour can be asserted in tests rather than inspected by
/// eye — v1's tracker called a `print` method that shadowed `Swift.print`, and passed
/// it the variadic array, so every line came out bracketed as `["…"]`.
public protocol AnalyticsLogSink: Sendable {
    func write(_ message: String)
}

/// Routes through unified logging.
public struct OSLogSink: AnalyticsLogSink {
    private let logger: Logger

    public init(subsystem: String = "com.analyticssystem", category: String = "Analytics") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func write(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}

/// Writes to standard output.
public struct StandardOutputLogSink: AnalyticsLogSink {
    public init() {}

    public func write(_ message: String) {
        print(message)
    }
}
