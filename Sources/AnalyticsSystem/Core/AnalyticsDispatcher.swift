import Foundation

/// Drains the command queue and fans each command out to the registered trackers.
///
/// A single consumer task processes the stream in order, which is what guarantees
/// that `logIn` reaches providers before an event tracked immediately after it —
/// something a detached `Task` per call could not promise.
struct AnalyticsDispatcher: Sendable {
    let registry: AnalyticsRegistry
    let identity: AnalyticsIdentityStore

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
        case let .logIn(user):
            await logIn(user, on: registrations)
        case .logOut:
            await logOut(on: registrations)
        case let .event(envelope):
            await deliver(envelope, to: registrations)
        case .barrier:
            break
        }
    }

    private func start(
        _ registrations: [AnalyticsRegistration],
        with context: AnalyticsStartContext
    ) async {
        let anonymousID = await identity.currentAnonymousID()
        for registration in registrations {
            await registration.tracker.start(with: context)
            await registration.tracker.identify(anonymousID: anonymousID)
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

    private func deliver(
        _ envelope: AnalyticsEventEnvelope,
        to registrations: [AnalyticsRegistration]
    ) async {
        for registration in registrations
        where registration.filter.admits(envelope.descriptor) {
            guard
                let record = envelope.resolve(registration.mapper),
                record.isValid
            else { continue }
            await registration.tracker.record(record)
        }
    }
}
