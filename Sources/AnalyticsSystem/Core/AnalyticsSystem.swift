//
//  AnalyticsSystem.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

public final class AnalyticsSystem {

    // MARK: - Properties
    // MARK: Content
    
    private(set) public lazy var isTrackersEnabled = true
    
    // MARK: Control
    
    private lazy var trackersControl = AnalyticsTrackersControl()
    private lazy var persistence = AnalyticsSystemPersistence()
    
    // MARK: Operations Queue
    
    private lazy var operationQueue: OperationQueue = .main
    
    
    // MARK: - Initialization
    
    public init() { }
    
    
    // MARK: - Configuration
    
    public func configureTrackers(
        with launchOptions: AnalyticsTrackersControl.LaunchOptions? = nil,
        configuration: @escaping (AnalyticsTrackersControl) throws -> Void
    ) rethrows {
        trackersControl.launchOptions = launchOptions
        
        try configuration(trackersControl)
    }
    
    public func setTrackersEnabled(_ isEnabled: Bool) {
        isTrackersEnabled = isEnabled
        
        trackersControl.all
            .forEach { tracker in
                tracker.setEnabled(isEnabled)
            }
    }
    
    
    // MARK: - Appearance
    
    public func initialize() {
        let initializator = persistence.initializator()
        
        trackersControl.all
            .forEach { tracker in
                tracker.configure(with: initializator)
            }
    }
    
    public func logIn(user: AnalyticsUser) {
        trackersControl.all
            .forEach { tracker in
                tracker.logIn(user: user)
            }
    }
    
    public func logOut(user: AnalyticsUser) {
        trackersControl.all
            .forEach { tracker in
                tracker.logOut(user: user)
            }
        
        persistence.clear()
        initialize()
    }
    
    public func track(
        event: AnalyticsEvent
    ) {
        guard isTrackersEnabled else { return }
        
        trackersControl.all
            .filter { tracker in
                tracker.isAvailable(eventType: event.type)
            }
            .forEach { tracker in
                let operation = AnalyticsEventOperation(event: event, tracker: tracker)
                operationQueue.addOperation(operation)
            }
    }
    
    public func appDidCrashLastLaunch() -> Bool {
        trackersControl.all
            .filter { tracker in
                tracker.canObserveAppCrashes()
            }
            .contains(where: { tracker in
                tracker.appDidCrashLastLaunch()
            })
    }
}
