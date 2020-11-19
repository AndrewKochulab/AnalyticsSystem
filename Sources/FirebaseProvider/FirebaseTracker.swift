//
//  FirebaseTracker.swift
//  
//
//  Created by Andrew Kochulab on 19.11.2020.
//

#if os(iOS)
import Foundation
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics
import AnalyticsSystem

open class FirebaseTracker<EventsFactory: AnalyticsTrackerFactory>: FactoryAnalyticsTracker<EventsFactory> {
    
    // MARK: - Properties
    
    public var crashlytics: Crashlytics {
        .crashlytics()
    }
    
    
    // MARK: - Configuration
    
    open override func initialize(with options: LaunchOptions? = nil) {
        FirebaseApp.configure()
    }
    
    open override func setEnabled(_ isEnabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
    }
    
    
    // MARK: - Auth
    
    open override func logIn(user: AnalyticsUser) {
        Analytics.setUserID(user.id)
        crashlytics.setUserID(user.id)
    }
    
    open override func logOut(user: AnalyticsUser) {
        Analytics.setUserID(nil)
        crashlytics.setUserID("")
    }
    
    
    // MARK: - Events
    
    open override func track(eventBuilder: AnalyticsEventBuilder) {
        Analytics.logEvent(
            eventBuilder.name,
            parameters: eventBuilder.attributes
        )
    }
}
#endif
