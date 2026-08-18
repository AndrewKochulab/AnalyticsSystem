#if Mixpanel

import AnalyticsSystem
import Foundation
import Mixpanel

/// Reports to Mixpanel.
///
/// Corrects two v1 defects. The API token is required by the only initializer, so the
/// `fatalError` initializer that existed purely to satisfy an inherited requirement is
/// gone. And `logOut` now calls `reset()`: v1 cleared only timed events and super
/// properties, which left the distinct ID in place, so a second user on the same
/// device was silently correlated with the first.
public struct MixpanelTracker: AnalyticsTracker {
    public let id: AnalyticsTrackerID
    private let apiToken: String
    private let instanceName: String?
    private let trackAutomaticEvents: Bool

    public init(
        id: AnalyticsTrackerID = .mixpanel,
        apiToken: String,
        instanceName: String? = nil,
        trackAutomaticEvents: Bool = false
    ) {
        self.id = id
        self.apiToken = apiToken
        self.instanceName = instanceName
        self.trackAutomaticEvents = trackAutomaticEvents
    }

    /// `Mixpanel.mainInstance()` traps when nothing has been initialised, so the
    /// non-trapping accessor is used throughout.
    private var instance: MixpanelInstance? {
        if let instanceName {
            return Mixpanel.getInstance(name: instanceName)
        }
        return Mixpanel.safeMainInstance()
    }

    // MARK: AnalyticsTracker

    public func start(with context: AnalyticsStartContext) async {
        guard instance == nil else { return }

        let options = MixpanelOptions(
            token: apiToken,
            instanceName: instanceName,
            trackAutomaticEvents: trackAutomaticEvents
        )
        Mixpanel.initialize(options: options)
    }

    public func setEnabled(_ isEnabled: Bool) async {
        guard let instance else { return }
        if isEnabled {
            instance.optInTracking()
        } else {
            instance.optOutTracking()
        }
    }

    public func identify(anonymousID: AnalyticsID) async {
        instance?.identify(distinctId: anonymousID.rawValue, usePeople: true)
    }

    public func logIn(user: AnalyticsUser) async {
        guard let instance else { return }

        instance.createAlias(
            user.id.rawValue,
            distinctId: instance.distinctId,
            usePeople: true
        )
        instance.identify(distinctId: user.id.rawValue, usePeople: true)

        let properties = user.mixpanelProperties
        if !properties.isEmpty {
            instance.people.set(properties: properties)
        }
    }

    public func logOut() async {
        guard let instance else { return }
        instance.clearTimedEvents()
        instance.clearSuperProperties()
        // The identity reset v1 omitted.
        instance.reset()
    }

    public func record(_ record: AnalyticsRecord) async {
        instance?.track(event: record.name, properties: record.payload.mixpanelProperties)
    }

    public func flushPendingEvents() async {
        instance?.flush()
    }
}

#else

import Foundation

@available(
    *,
    unavailable,
    message: """
    MixpanelTracker requires the "Mixpanel" package trait. Add it to your dependency:
    .package(url: "https://github.com/AndrewKochulab/AnalyticsSystem.git", from: "2.0.0", traits: ["Mixpanel"])
    """
)
public enum MixpanelTracker {}

#endif
