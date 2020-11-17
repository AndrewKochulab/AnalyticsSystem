//
//  AnalyticsUser.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

public protocol AnalyticsUser {
    
    // MARK: - Properties
    
    var id: String { get }
    var firstName: String? { get }
    var lastName: String? { get }
    var email: String? { get }
    
}

public typealias AnalyticsUserAttributes = [String : Any]
