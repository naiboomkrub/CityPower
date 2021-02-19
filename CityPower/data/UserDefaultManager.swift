//
//  UserDefaultManager.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/9/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit

struct UserDefaultsManager {
    
    private static func get<T>(property: PreferencesManager.Properties) -> T {
        return PreferencesManager.standard.valueOrDefault(for: property)
    }
    private static func set<T>(property: PreferencesManager.Properties, value: T) {
        PreferencesManager.standard[property] = value
    }
    
    static var score: Int {
        get { return get(property: .score) }
        set { set(property: .score, value: newValue) }
    }
    
    static var correctAnswers: Int {
        get { return get(property: .correctAnswers) }
        set { set(property: .correctAnswers, value: newValue) }
    }
    
    static var incorrectAnswers: Int {
        get { return get(property: .incorrectAnswers) }
        set { set(property: .incorrectAnswers, value: newValue) }
    }
    
    static var username: String{
        get { return get(property: .username) }
        set { set(property: .username, value: newValue) }
    }

}
