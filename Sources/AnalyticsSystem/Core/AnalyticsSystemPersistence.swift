//
//  AnalyticsSystemPersistence.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

final class AnalyticsSystemPersistence {
    
    // MARK: - Properties
    
    @UserDefault(key: "AnalyticsSystemPersistence.AnalyticsID", defaultValue: nil)
    private var identifier: AnalyticsID?
    
    
    // MARK: - Appearance
    
    func initializator() -> AnalyticsID {
        var analyticsIdentifier: AnalyticsID
        
        if let storedIdentifier = identifier {
            analyticsIdentifier = storedIdentifier
        } else {
            analyticsIdentifier = uniqueAnalyticsIdentifier()
            self.identifier = analyticsIdentifier
        }
        
        return analyticsIdentifier
    }
    
    func clear() {
        identifier = nil
    }
    
    private func uniqueAnalyticsIdentifier() -> String {
        UUID().uuidString
    }
}
