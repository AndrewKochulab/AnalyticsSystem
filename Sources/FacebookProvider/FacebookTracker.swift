//
//  FacebookTracker.swift
//  
//
//  Created by Andrew Kochulab on 19.11.2020.
//

#if os(iOS)
import Foundation
import FBSDKCoreKit
import AnalyticsSystem

final class FacebookTracker<EventsFactory: AnalyticsTrackerFactory>: FactoryAnalyticsTracker<EventsFactory> {
    
    // MARK: - Properties
    
    public lazy var settings: Settings.Type = Settings.self
    
    
    // MARK: - Configuration
    
    open override func initialize(with options: LaunchOptions? = nil) {
        settings.isAdvertiserIDCollectionEnabled = false
        ApplicationDelegate.initializeSDK(options)
    }
    
    open override func setEnabled(_ isEnabled: Bool) {
        settings.isAutoLogAppEventsEnabled = isEnabled
        settings.isAdvertiserIDCollectionEnabled = isEnabled
    }
    
    
    // MARK: - Auth
    
    open override func logIn(user: AnalyticsUser) {
        AppEvents.setUser(
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            phone: nil,
            dateOfBirth: nil,
            gender: nil,
            city: nil,
            state: nil,
            zip: nil,
            country: nil
        )
    }
    
    open override func logOut(user: AnalyticsUser) {
        AppEvents.clearUserID()
        AppEvents.clearUserData()
    }
    
    
    // MARK: - Events
    
    open override func track(eventBuilder: AnalyticsEventBuilder) {
        AppEvents.logEvent(
            AppEvents.Name(rawValue: eventBuilder.name),
            parameters: eventBuilder.attributes
        )
    }
}
#endif
