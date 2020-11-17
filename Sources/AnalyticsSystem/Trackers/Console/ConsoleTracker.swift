//
//  ConsoleTracker.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 17.11.2020.
//

import Foundation

open class ConsoleTracker<EventsFactory: AnalyticsTrackerFactory>: FactoryAnalyticsTracker<EventsFactory> {
    
    // MARK: - Configuration
    
    open override func initialize(with options: LaunchOptions? = nil) {
        print("Console tracker successfully connected")
    }
    
    
    // MARK: - Auth
    
    open override func logIn(user: AnalyticsUser) {
        print("\(user.firstName ?? "") \(user.lastName ?? "") successfully logged in")
    }
    
    open override func logOut(user: AnalyticsUser) {
        print("\(user.firstName ?? "") \(user.lastName ?? "") successfully logged out")
    }
    
    
    // MARK: - Events
    
    open override func track(eventBuilder: AnalyticsEventBuilder) {
        print(eventBuilder.description)
    }
    
    
    // MARK: - Helpers
    
    open func print(
        _ items: Any...,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        Swift.print(
            items,
            separator: separator,
            terminator: terminator
        )
    }
}
