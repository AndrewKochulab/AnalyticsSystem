//
//  FactoryAnalyticsTracker.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 17.11.2020.
//

import Foundation

public protocol AnalyticsTrackerFactory {
    
    // MARK: - Initialization
    
    init()
    
    
    // MARK: - Builder
    
    func builder(
        for event: AnalyticsEvent
    ) -> AnalyticsEventBuilder
    
}

open class FactoryAnalyticsTracker<EventsFactory: AnalyticsTrackerFactory>: AnalyticsTracker {
    
    // MARK: - Properties
    
    public let eventsFactory: EventsFactory
    public var isEventAvailable: IsEventAvailable = { _ in true }
    
    
    // MARK: - Initialization
    
    public required init(eventsFactory: EventsFactory = .init()) {
        self.eventsFactory = eventsFactory
    }
    
    
    // MARK: - Configuration
    
    open func initialize(with options: LaunchOptions?) { }
    
    open func configure(with identifier: AnalyticsID) { }
    
    open func setEnabled(_ isEnabled: Bool) { }
    
    
    // MARK: - Auth
    
    open func logIn(user: AnalyticsUser) { }
    
    open func logOut(user: AnalyticsUser) { }
    
    
    // MARK: - Events
    
    open func track(event: AnalyticsEvent) {
        let eventBuilder = self.eventBuilder(for: event)
        
        guard validate(eventBuilder: eventBuilder) else {
            return
        }
        
        track(eventBuilder: eventBuilder)
    }
    
    open func track(eventBuilder: AnalyticsEventBuilder) {
        
    }
    
    open func eventBuilder(
        for event: AnalyticsEvent
    ) -> AnalyticsEventBuilder {
        eventsFactory.builder(for: event)
    }
    
    open func validate(
        eventBuilder: AnalyticsEventBuilder
    ) -> Bool {
        !eventBuilder.name.isEmpty
    }
    
    open func isAvailable(eventType: AnalyticsEventType) -> Bool {
        isEventAvailable(eventType)
    }
    
    
    // MARK: - Crashes
    
    open func canObserveAppCrashes() -> Bool { false }
    
    open func appDidCrashLastLaunch() -> Bool { false }
    
}

public extension AnalyticsTrackerFactory {
    
    // MARK: - Configuration
    
    func eventContent<Event: AnalyticsEvent>(
        for event: AnalyticsEvent,
        of type: Event.Type = Event.self
    ) -> Event {
        event as! Event // safe operation
    }
}
