//
//  AnalyticsEventBuilder.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

public class AnalyticsEventBuilder {
    
    // MARK: - Properties
    
    public let name: AnalyticsEventName
    public let attributes: AnalyticsEventAttributes
    
    public var description: String {
        """
            📱 Event Name: \(name)
            📱 Attributes: \(attributes.compactMap { "\($0.key) : \($0.value)" })
        """
    }
    
    
    // MARK: - Initialization
    
    public init(
        name: AnalyticsEventName,
        attributes: AnalyticsEventAttributes = [:]
    ) {
        self.name = name
        self.attributes = attributes
    }
}
