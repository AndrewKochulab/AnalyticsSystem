//
//  AnalyticsTrackersControl.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

public final class AnalyticsTrackersControl {
    
    // MARK: - Types
    
    public typealias LaunchOptions = AnalyticsTracker.LaunchOptions
    typealias TrackersContainer = [String : AnalyticsTracker]
    
    enum Error: String, LocalizedError {
        case trackerAlreadyExists = "This analytics tracker already exists"
        case trackerNotExists = "This analytics tracker not exists"
        
        var errorDescription: String? {
            rawValue
        }
    }
    
    
    // MARK: - Properties
    
    var launchOptions: LaunchOptions?
    private lazy var containers = TrackersContainer()
    
    var all: [AnalyticsTracker] {
        Array(containers.values)
    }
    
    
    // MARK: - Appearance
    
    public func addTracker(
        _ tracker: AnalyticsTracker
    ) throws {
        let rawRepresentation = self.rawRepresentation(from: tracker)
        
        guard containers[rawRepresentation] == nil else {
            throw Error.trackerAlreadyExists
        }
        
        containers[rawRepresentation] = tracker
        
        tracker.initialize(with: launchOptions)
    }
    
    public func addTracker<Tracker, Factory>(
        _ tracker: Tracker.Type,
        with factory: Factory
    ) throws where
        Tracker: FactoryAnalyticsTracker<Factory>
    {
        try addTracker(
            tracker.init(eventsFactory: factory)
        )
    }
    
    public func removeTracker(
        _ tracker: AnalyticsTracker
    ) throws {
        let rawRepresentation = self.rawRepresentation(from: tracker)
        
        guard containers[rawRepresentation] != nil else {
            throw Error.trackerNotExists
        }
        
        containers.removeValue(forKey: rawRepresentation)
    }
    
    private func rawRepresentation(
        from tracker: AnalyticsTracker
    ) -> String {
        String(describing: tracker)
    }
}
