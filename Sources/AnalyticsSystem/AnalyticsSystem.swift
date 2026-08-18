import Foundation

/// Fans analytics events out to any number of registered providers.
///
/// ```swift
/// let analytics = AnalyticsSystem()
/// try await analytics.register(ConsoleTracker())
/// await analytics.start()
///
/// analytics.track(SignUpEvent(method: .email))   // sync, callable from anywhere
/// ```
///
/// ## Concurrency
///
/// This is a `Sendable` class rather than an actor, on purpose. Making it an actor
/// would force `await analytics.track(…)` at every call site, putting a suspension
/// point into UI paths for what is a fire-and-forget logging call. Instead the
/// mutable state lives in an ``AnalyticsRegistry`` actor behind the facade, and all
/// work is funnelled through one serial queue.
///
/// That queue also provides the ordering guarantee: a `logIn` followed by a `track`
/// reaches every provider in that order.
public final class AnalyticsSystem: Sendable {
    /// How the serial queue behaves when events arrive faster than they drain.
    public enum QueuePolicy: Hashable, Sendable {
        /// Never drop an event. The default: for analytics, unbounded growth under a
        /// pathological event storm is the lesser evil versus silently losing data.
        case unbounded
        /// Retain at most `limit` pending items, discarding the oldest first.
        case bufferingNewest(limit: Int)
    }

    /// Injection points for persistence, identity generation, and queue behaviour.
    public struct Configuration: Sendable {
        public var store: any AnalyticsStore
        public var idGenerator: @Sendable () -> AnalyticsID
        public var queuePolicy: QueuePolicy

        /// - Parameters:
        ///   - store: Backing store for the anonymous identity.
        ///   - idGenerator: Anonymous ID factory. Override in tests for determinism.
        ///   - queuePolicy: Defaults to ``QueuePolicy/unbounded``.
        public init(
            store: any AnalyticsStore = UserDefaultsAnalyticsStore(),
            idGenerator: @escaping @Sendable () -> AnalyticsID = AnalyticsID.random,
            queuePolicy: QueuePolicy = .unbounded
        ) {
            self.store = store
            self.idGenerator = idGenerator
            self.queuePolicy = queuePolicy
        }
    }

    private let registry: AnalyticsRegistry
    private let identity: AnalyticsIdentityStore
    private let continuation: AsyncStream<AnalyticsWorkItem>.Continuation
    private let pump: Task<Void, Never>

    /// Read on the synchronous `track` path, so it is a lock rather than actor state.
    private let enabled = Locked<Bool>(true)

    public init(configuration: Configuration = Configuration()) {
        let registry = AnalyticsRegistry()
        let identity = AnalyticsIdentityStore(
            store: configuration.store,
            generate: configuration.idGenerator
        )
        self.registry = registry
        self.identity = identity

        let bufferingPolicy: AsyncStream<AnalyticsWorkItem>.Continuation.BufferingPolicy =
            switch configuration.queuePolicy {
            case .unbounded: .unbounded
            case let .bufferingNewest(limit): .bufferingNewest(limit)
            }

        let (stream, continuation) = AsyncStream<AnalyticsWorkItem>.makeStream(
            bufferingPolicy: bufferingPolicy
        )
        self.continuation = continuation

        let dispatcher = AnalyticsDispatcher(registry: registry, identity: identity)
        self.pump = Task.detached(priority: .utility) {
            await dispatcher.run(stream)
        }
    }

    deinit {
        continuation.finish()
        pump.cancel()
    }

    // MARK: - Registration

    /// Registers a tracker along with how it should render and filter events.
    ///
    /// - Throws: ``AnalyticsError/duplicateTracker(_:)`` if the identifier is taken.
    public func register(
        _ tracker: some AnalyticsTracker,
        mapper: AnalyticsEventMapper = AnalyticsEventMapper(),
        filter: AnalyticsEventFilter = .all
    ) async throws {
        try await registry.register(
            AnalyticsRegistration(tracker: tracker, mapper: mapper, filter: filter)
        )
    }

    /// - Throws: ``AnalyticsError/unknownTracker(_:)`` if nothing is registered.
    public func unregister(_ id: AnalyticsTrackerID) async throws {
        try await registry.unregister(id)
    }

    public var trackerIDs: [AnalyticsTrackerID] {
        get async { await registry.trackerIDs }
    }

    public func isRegistered(_ id: AnalyticsTrackerID) async -> Bool {
        await registry.contains(id)
    }

    // MARK: - Lifecycle

    /// Boots every registered tracker and hands it the current anonymous identity.
    public func start(with context: AnalyticsStartContext = .empty) async {
        await enqueueAwaiting(.start(context))
    }

    /// Toggles collection across all trackers.
    ///
    /// Takes effect immediately for events tracked after this call returns; events
    /// already queued are still delivered, since ordering is preserved.
    public func setEnabled(_ isEnabled: Bool) async {
        enabled.withLock { $0 = isEnabled }
        await enqueueAwaiting(.setEnabled(isEnabled))
    }

    public var isEnabled: Bool {
        enabled.withLock { $0 }
    }

    public func logIn(user: AnalyticsUser) async {
        await enqueueAwaiting(.logIn(user))
    }

    /// Logs out everywhere and rotates the anonymous identity.
    public func logOut() async {
        await enqueueAwaiting(.logOut)
    }

    /// Returns once every command enqueued before this call has been delivered.
    public func flush() async {
        await enqueueAwaiting(.barrier)
    }

    // MARK: - Tracking

    /// Reports an event to every tracker that admits it.
    ///
    /// Synchronous, non-throwing, and callable from any isolation domain.
    public func track(_ event: some AnalyticsEvent) {
        guard enabled.withLock({ $0 }) else { return }
        continuation.yield(
            AnalyticsWorkItem(command: .event(AnalyticsEventEnvelope(event)))
        )
    }

    // MARK: - Queries

    /// `true` if any crash-reporting provider saw a crash on the previous launch.
    public func didCrashOnLastLaunch() async -> Bool {
        for reporter in await registry.crashReporters {
            guard await reporter.didCrashOnLastLaunch() else { continue }
            return true
        }
        return false
    }

    // MARK: - Plumbing

    private func enqueueAwaiting(_ command: AnalyticsCommand) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.continuation.yield(
                AnalyticsWorkItem(command: command) { continuation.resume() }
            )
        }
    }
}
