import Foundation

/// A unit of work on the serial analytics queue.
enum AnalyticsCommand: Sendable {
    case start(AnalyticsStartContext)
    case setEnabled(Bool)
    case logIn(AnalyticsUser)
    case logOut
    case event(AnalyticsEventEnvelope)
    /// Carries no work; used by `flush()` to observe that everything queued
    /// before it has been delivered.
    case barrier
}

/// A command plus an optional acknowledgement, resumed once the command has been
/// fully delivered to every tracker.
struct AnalyticsWorkItem: Sendable {
    let command: AnalyticsCommand
    let acknowledge: (@Sendable () -> Void)?

    init(command: AnalyticsCommand, acknowledge: (@Sendable () -> Void)? = nil) {
        self.command = command
        self.acknowledge = acknowledge
    }
}
