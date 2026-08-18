import Foundation

/// Drains the command queue and fans each command out to the registered trackers.
///
/// A single consumer task processes the stream in order, which is what guarantees
/// that `logIn` reaches providers before an event tracked immediately after it —
/// something a detached `Task` per call could not promise.
///
/// The dispatcher owns the only mutable state outside the registry (whether `start`
/// has run, the held events, and the global properties). Because exactly one task
/// runs `run(_:)`, that state needs no synchronisation of its own.
final class AnalyticsDispatcher {
    private let registry: AnalyticsRegistry
    private let identity: AnalyticsIdentityStore
    private let startupBuffer: AnalyticsStartupBuffer
    private let diagnostics: AnalyticsDiagnosticHandler?

    private var hasStarted = false
    private var heldEvents: [AnalyticsEventEnvelope] = []
    private var globalProperties = AnalyticsPayload.empty

    init(
        registry: AnalyticsRegistry,
        identity: AnalyticsIdentityStore,
        startupBuffer: AnalyticsStartupBuffer,
        diagnostics: AnalyticsDiagnosticHandler?
    ) {
        self.registry = registry
        self.identity = identity
        self.startupBuffer = startupBuffer
        self.diagnostics = diagnostics
    }

    func run(_ stream: AsyncStream<AnalyticsWorkItem>) async {
        for await item in stream {
            await perform(item.command)
            item.acknowledge?()
        }
    }

    private func perform(_ command: AnalyticsCommand) async {
        // Snapshot first, then release the actor: no vendor SDK call is ever made
        // while holding the registry.
        let registrations = await registry.snapshot()

        switch command {
        case let .start(context):
            await start(registrations, with: context)
        case let .setEnabled(isEnabled):
            await setEnabled(isEnabled, on: registrations)
        case let .setGlobalProperties(properties):
            globalProperties = properties
        case let .logIn(user):
            await logIn(user, on: registrations)
        case .logOut:
            await logOut(on: registrations)
        case let .event(envelope):
            await handle(envelope, registrations: registrations)
        case .flushProviders:
            await flushProviders(registrations)
        case .barrier:
            break
        }
    }

    // MARK: Lifecycle

    private func start(
        _ registrations: [AnalyticsRegistration],
        with context: AnalyticsStartContext
    ) async {
        let anonymousID = await identity.currentAnonymousID()
        for registration in registrations {
            await registration.tracker.start(with: context)
            await registration.tracker.identify(anonymousID: anonymousID)
        }

        hasStarted = true

        // Replay anything held during launch, in the order it was tracked.
        let held = heldEvents
        heldEvents = []
        for envelope in held {
            await deliver(envelope, to: registrations)
        }
    }

    private func setEnabled(
        _ isEnabled: Bool,
        on registrations: [AnalyticsRegistration]
    ) async {
        for registration in registrations {
            await registration.tracker.setEnabled(isEnabled)
        }
    }

    private func logIn(
        _ user: AnalyticsUser,
        on registrations: [AnalyticsRegistration]
    ) async {
        for registration in registrations {
            await registration.tracker.logIn(user: user)
        }
    }

    private func logOut(on registrations: [AnalyticsRegistration]) async {
        for registration in registrations {
            await registration.tracker.logOut()
        }
        // Rotate afterwards so providers see the log out before the new identity.
        let rotated = await identity.rotateAnonymousID()
        for registration in registrations {
            await registration.tracker.identify(anonymousID: rotated)
        }
    }

    private func flushProviders(_ registrations: [AnalyticsRegistration]) async {
        for registration in registrations {
            await registration.tracker.flushPendingEvents()
        }
    }

    // MARK: Events

    private func handle(
        _ envelope: AnalyticsEventEnvelope,
        registrations: [AnalyticsRegistration]
    ) async {
        guard shouldHold else {
            await deliver(envelope, to: registrations)
            return
        }
        hold(envelope)
    }

    private var shouldHold: Bool {
        guard case .buffered = startupBuffer else { return false }
        return !hasStarted
    }

    private func hold(_ envelope: AnalyticsEventEnvelope) {
        guard case let .buffered(limit) = startupBuffer else { return }

        if limit <= 0 {
            diagnostics?(.bufferOverflow(dropped: envelope.descriptor.name, limit: limit))
            return
        }

        heldEvents.append(envelope)
        diagnostics?(.buffered(envelope.descriptor.name))

        while heldEvents.count > limit {
            let dropped = heldEvents.removeFirst()
            diagnostics?(.bufferOverflow(dropped: dropped.descriptor.name, limit: limit))
        }
    }

    private func deliver(
        _ envelope: AnalyticsEventEnvelope,
        to registrations: [AnalyticsRegistration]
    ) async {
        for registration in registrations
        where registration.filter.admits(envelope.descriptor) {
            guard let mapped = envelope.resolve(registration.mapper) else {
                diagnostics?(.unmapped(envelope.descriptor.name, tracker: registration.id))
                continue
            }

            let merged = AnalyticsRecord(
                name: mapped.name,
                // Event attributes win over global ones on conflict.
                payload: globalProperties.merging(mapped.payload)
            )

            switch registration.validator(merged) {
            case let .accept(record):
                if record.name != merged.name {
                    diagnostics?(
                        .sanitized(from: merged.name, to: record.name, tracker: registration.id)
                    )
                }
                await registration.tracker.record(record)

            case let .reject(reason):
                diagnostics?(
                    .rejected(merged.name, tracker: registration.id, reason: reason)
                )
            }
        }
    }
}
