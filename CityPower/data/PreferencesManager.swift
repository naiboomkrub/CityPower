//
//  PreferencesManager.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/9/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation

@dynamicMemberLookup
class PreferencesManager {
    
    enum Properties: String {
        
        case score
        case correctAnswers
        case incorrectAnswers
        case username
        
        var defaultvalue: Any {
            switch self {
            case .score: return 0
            case .correctAnswers: return 0
            case .incorrectAnswers: return 0
            case .username: return "Name"
            }
        }
    }

    static let standard = PreferencesManager()
    private let userDefaults: UserDefaults
    
    init() { self.userDefaults = .standard }
    
    func valueOrDefault<T>(for property: Properties) -> T! {
        return self[property] ?? (property.defaultvalue as! T)
    }
    
    subscript<T>(property: Properties) -> T? {
        get { return self[dynamicMember: property.rawValue] }
        set { self[dynamicMember: property.rawValue] = newValue }
    }
    subscript<T>(dynamicMember propertyKey: String) -> T? {
        get { return self.userDefaults.value(fromKey: propertyKey) }
        set { self.userDefaults.set(newValue, forKey: propertyKey) }
    }
    
    func setMultiple(_ values: [Properties: Any]) {
        values.forEach { self[$0.key] = $0.value }
    }

    func remove(property: Properties) {
        self.userDefaults.removeObject(forKey: property.rawValue)
    }
}

extension UserDefaults {
    
    func value<T>(fromKey propertyKey: String) -> T? {
        guard self.object(forKey: propertyKey) != nil else { return nil }
        switch T.self {
        case is Int.Type: return self.integer(forKey: propertyKey) as? T
        case is String.Type: return self.string(forKey: propertyKey) as? T
        case is Double.Type: return self.double(forKey: propertyKey) as? T
        case is Float.Type: return self.float(forKey: propertyKey) as? T
        case is Bool.Type: return self.bool(forKey: propertyKey) as? T
        case is URL.Type: return self.url(forKey: propertyKey) as? T
        case is Data.Type: return self.data(forKey: propertyKey) as? T
        case is [String].Type: return self.stringArray(forKey: propertyKey) as? T
        case is [Any].Type: return self.array(forKey: propertyKey) as? T
        case is [String: Any?].Type: return self.dictionary(forKey: propertyKey) as? T
        default: return self.object(forKey: propertyKey) as? T
        }
    }
}
