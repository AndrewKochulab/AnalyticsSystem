//
//  AnalyticsEventOperation.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

final class AnalyticsEventOperation: Operation {
    
    // MARK: - Properties
    
    let event: AnalyticsEvent
    let tracker: AnalyticsTracker
    
    
    // MARK: - Initialization
    
    init(
        event: AnalyticsEvent,
        tracker: AnalyticsTracker
    ) {
        self.event = event
        self.tracker = tracker
    }
    
    
    // MARK: - Appearance
    
    override func main() {
        if isCancelled {
            return
        }
        
        tracker.track(event: event)
    }
}
