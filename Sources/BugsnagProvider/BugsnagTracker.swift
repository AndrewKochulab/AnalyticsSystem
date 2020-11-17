//
//  File.swift
//  
//
//  Created by Andrew Kochulab on 17.11.2020.
//

import Foundation
import Bugsnag
import AnalyticsSystem

open class BugsnagTracker<EventsFactory: AnalyticsTrackerFactory>: FactoryAnalyticsTracker<EventsFactory> {
    
    // MARK: - Properties
    
    private let apiToken: String
    
    
    // MARK: - Initialization
    
    public required init(
        apiToken: String,
        eventsFactory: EventsFactory = .init()
    ) {
        self.apiToken = apiToken
        
        super.init(eventsFactory: eventsFactory)
    }
    
    public required init(
        eventsFactory: EventsFactory
    ) {
        fatalError("Please use initializer with apiToken")
    }
    
    
    // MARK: - Configuration
    
    open override func initialize(with options: LaunchOptions? = nil) {
        let config = BugsnagConfiguration(apiToken)
        
        Bugsnag.start(with: config)
    }
    
    
    // MARK: - Auth
    
    open override func logIn(user: AnalyticsUser) {
        Bugsnag.setUser(
            user.id,
            withEmail: user.email,
            andName: "\(user.firstName ?? "") \(user.lastName ?? "")"
        )
    }
    
    open override func logOut(user: AnalyticsUser) {
        Bugsnag.setUser(
            nil,
            withEmail: nil,
            andName: nil
        )
    }
    
    
    // MARK: - Events
    
    open override func isAvailable(eventType: AnalyticsEventType) -> Bool {
        false
    }
    
    
    // MARK: - Crashes
    
    open override func canObserveAppCrashes() -> Bool { true }
    
    open override func appDidCrashLastLaunch() -> Bool {
        Bugsnag.appDidCrashLastLaunch()
    }
}
