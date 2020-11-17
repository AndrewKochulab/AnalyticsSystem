//
//  UserDefault.swift
//  AnalyticsSystem
//
//  Created by Andrew Kochulab on 16.11.2020.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
    
    // MARK: - Properties
    
    let key: String
    let defaultValue: T
    let container: UserDefaults
    
    var wrappedValue: T {
        get { container.object(forKey: key) as? T ?? defaultValue }
        set {
            container.set(newValue, forKey: key)
            container.synchronize()
        }
    }
    
    
    // MARK: - Initialization
    
    init(
        key: String,
        defaultValue: T,
        container: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }
}
