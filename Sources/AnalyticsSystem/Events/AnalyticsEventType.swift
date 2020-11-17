//
//  AnalyticsEventType.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

public struct AnalyticsEventType: OptionSet {
    
    // MARK: - Properties
    
    public let rawValue: Int
    
    
    // MARK: - Initialization
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
