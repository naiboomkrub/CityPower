//
//  DataStoreArchiver.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import UIKit

class DataStoreArchiver: NSObject, NSCoding, NSSecureCoding {
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    enum Keys: String {
        case dateSchedule
    }
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static let fileURL = documentsDirectory.appendingPathComponent("DataStore.data")
    
    var dateSchedule: [String: [Int:String]] = [:]
    
    static var shared = DataStoreArchiver()
    fileprivate override init() { }

    func encode(with archiver: NSCoder) {
        archiver.encode(dateSchedule, forKey: Keys.dateSchedule.rawValue)
    }

    required init (coder unarchiver: NSCoder) {
        super.init()
        if let dateSchedule = unarchiver.decodeObject(forKey: Keys.dateSchedule.rawValue) as? [String: [Int:String]] {
            self.dateSchedule = dateSchedule
        }
    }
    
    func save() {
        
        if let dataToBeArchived = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true) {
            try? dataToBeArchived.write(to: DataStoreArchiver.fileURL)
        }
    }
}
