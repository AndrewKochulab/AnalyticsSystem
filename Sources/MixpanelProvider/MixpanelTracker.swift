//
//  MixpanelTracker.swift
//  
//
//  Created by Andrew Kochulab on 17.11.2020.
//

#if os(iOS)
import Foundation
import Mixpanel
import AnalyticsSystem

open class MixpanelTracker<EventsFactory: AnalyticsTrackerFactory>: FactoryAnalyticsTracker<EventsFactory> {
    
    // MARK: - Types
    
    open enum UserAttribute: String {
        case firstName = "first_name"
        case lastName = "last_name"
        case emailAddress = "email_address"
    }
    
    
    // MARK: - Properties
    
    open var mixpanel: MixpanelInstance {
        Mixpanel.mainInstance()
    }
    
    
    // MARK: - Configuration
    
    open override func initialize(with options: LaunchOptions? = nil) {
        Mixpanel.initialize(token: "token")
    }
    
    open override func setEnabled(_ isEnabled: Bool) {
        if isEnabled {
            mixpanel.optInTracking()
        } else {
            mixpanel.optOutTracking()
        }
    }
    
    open override func configure(with identifier: AnalyticsID) {
        mixpanel.identify(
            distinctId: identifier,
            usePeople: true
        )
    }
    
    
    // MARK: - Auth
    
    open override func logIn(user: AnalyticsUser) {
        mixpanel.createAlias(
            user.id,
            distinctId: mixpanel.distinctId,
            usePeople: true
        )
        
        mixpanel.people.set(
            properties: userAttributes(from: user)
        )
    }
    
    open override func logOut(user: AnalyticsUser) {
        mixpanel.clearTimedEvents()
        mixpanel.clearSuperProperties()
    }
    
    
    // MARK: - Events
    
    open override func track(eventBuilder: AnalyticsEventBuilder) {
        mixpanel.track(
            event: eventBuilder.name,
            properties: eventAttributes(from: eventBuilder.attributes)
        )
    }
    
    open override func isAvailable(eventType: AnalyticsEventType) -> Bool {
        switch eventType {
            case .signIn,
                 .signUp:
                return true
                
            case .crashRecovery:
                return false
                
            default:
                return false
        }
    }
    
    
    // MARK: - Converters
    
    open func userAttributes(
        from user: AnalyticsUser
    ) -> [String : MixpanelType] {
        return [
            UserAttribute.firstName.rawValue : user.firstName ?? "",
            UserAttribute.lastName.rawValue : user.lastName ?? "",
            UserAttribute.emailAddress.rawValue : user.email ?? ""
        ]
    }
    
    open func eventAttributes(
        from attributes: AnalyticsEventAttributes
    ) -> [String : MixpanelType] {
        var dict = [String : MixpanelType]()
        
        attributes.forEach { key, value in
            dict[key] = value as? MixpanelType
        }
        
        return dict
    }
}
#endif
