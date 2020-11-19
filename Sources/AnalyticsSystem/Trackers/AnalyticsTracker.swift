//
//  AnalyticsTracker.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

#if os(iOS)
import UIKit
#else
import Foundation
#endif

public protocol AnalyticsTracker {
    
    // MARK: - Types
    
    #if canImport(UIKit)
    typealias LaunchOptions = [UIApplication.LaunchOptionsKey : Any]
    #else
    typealias LaunchOptions = [String : Any]
    #endif
    
    typealias IsEventAvailable = (_ eventType: AnalyticsEventType) -> Bool
    
    
    // MARK: - Properties
    
    var isEventAvailable: IsEventAvailable { get set }
    
    
    // MARK: - Configuration
    
    func initialize(with options: LaunchOptions?)
    
    func configure(with identifier: AnalyticsID)
    
    func setEnabled(_ isEnabled: Bool)
    
    
    // MARK: - Auth
    
    func logIn(user: AnalyticsUser)
    
    func logOut(user: AnalyticsUser)
    
    
    // MARK: - Events
    
    func track(event: AnalyticsEvent)
    
    func track(eventBuilder: AnalyticsEventBuilder)
    
    func isAvailable(eventType: AnalyticsEventType) -> Bool
    
    
    // MARK: - Crashes
    
    func canObserveAppCrashes() -> Bool
    
    func appDidCrashLastLaunch() -> Bool
    
}
