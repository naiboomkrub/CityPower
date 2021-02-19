//
//  EventTask.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 2/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxDataSources

struct InstallHistory: Codable {
    let machineLabel : String
    let data1: [ContentStruct]
    let data2: [ContentStruct]
    let timeStamp: String
    let topic: String
}

extension InstallHistory: Hashable {
    static func == (lhs: InstallHistory, rhs: InstallHistory) -> Bool {
        return lhs.machineLabel == rhs.machineLabel &&
            lhs.timeStamp == rhs.timeStamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(machineLabel)
        hasher.combine(timeStamp)
    }
}

extension InstallHistory: IdentifiableType {
    var identity: String {
        return self.machineLabel + self.timeStamp
    }
    
    typealias Identity = String
}


class InstallHistories {
    
    static let shared = InstallHistories()
    static let fileManager = FileManager.default
    var savedTask: [InstallHistory] = []
    
    func loadTask()  {

        let documentsURL = InstallHistories.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let taskAll = self.loadFromJSONFilesOfDirectory(url: documentsURL) as! [InstallHistory]
        
        for task in taskAll {
            self.savedTask.append(task) }
        
    }
    
    func removeTask() {
        
        let fileName =  "installhistories.json"
            
        if let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    @discardableResult func swap(index: Int, target: Int, item: InstallHistory) -> Bool {
        
        guard target < InstallHistories.shared.savedTask.count else { return false }
        
        let fileName = "installhistories.json"
        InstallHistories.shared.savedTask.remove(at: index)
        InstallHistories.shared.savedTask.insert(item, at: target)
  
        if let documentsURL = InstallHistories.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(InstallHistories.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    @discardableResult func remove(index: Int) -> Bool {
        
        guard index < InstallHistories.shared.savedTask.count else { return false }
        
        let fileName = "installhistories.json"
        InstallHistories.shared.savedTask.remove(at: index)
  
        if let documentsURL = InstallHistories.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(InstallHistories.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    
    @discardableResult func edit(newTask: InstallHistory, task: InstallHistory) -> Bool {
    
        guard InstallHistories.shared.savedTask.contains(task) else { return false }
        
        let fileName = "installhistories.json"
        
        if let replace = InstallHistories.shared.savedTask.firstIndex(of: task) {
            InstallHistories.shared.savedTask[replace] = newTask
                        
        if let documentsURL = InstallHistories.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(InstallHistories.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
                }
            }
        }
        return false
    }
    
    @discardableResult func save(task: InstallHistory) -> Bool {
    
        guard !InstallHistories.shared.savedTask.contains(task) else { return false }
        
        let fileName = "installhistories.json"
        InstallHistories.shared.savedTask.append(task)
  
        if let documentsURL = InstallHistories.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(InstallHistories.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    private func loadFromJSONFilesOfDirectory(url contentURL: URL?) -> Any {
        
        if let validURL = contentURL,
           let contentOfFilesPath = (try? InstallHistories.fileManager.contentsOfDirectory(at: validURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) {
            
            for url in contentOfFilesPath where url.lastPathComponent == "installhistories.json" {
                do {
                    let data = try Data(contentsOf: url)
                    let task = try JSONDecoder().decode([InstallHistory].self, from: data)
                    return task
                    
                } catch {
                    print("Failed to write JSON data: \(error.localizedDescription)")
                }
            }
        }
        return []
    }
}
