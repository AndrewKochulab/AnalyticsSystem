//
//  AnalyticsEvent.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

public typealias AnalyticsEventName = String
public typealias AnalyticsEventAttributes = [String : Any]

public protocol AnalyticsEvent {
    
    // MARK: - Types
    
    typealias Attributes = AnalyticsEventAttributes
    
    
    // MARK: - Properties
    
    var type: AnalyticsEventType { get }
    
}
