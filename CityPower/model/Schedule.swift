//
//  Schedule.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxDataSources

struct Task: Codable {
    let date : String
    let labour: String
    let eventTask: String
    let timeStamp: String
    let done: Bool
}

extension Task: Hashable {
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.date == rhs.date &&
            lhs.labour == rhs.labour &&
            lhs.eventTask == rhs.eventTask &&
            lhs.timeStamp == rhs.timeStamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(labour)
        hasher.combine(eventTask)
        hasher.combine(timeStamp)
    }
}

extension Task: IdentifiableType {
    var identity: String {
        return self.timeStamp + self.eventTask
    }
    
    typealias Identity = String
}

class Schedule {
    
    static let shared = Schedule()
    static let fileManager = FileManager.default
    var savedTask: [Task] = []
    
    func loadTask() {

        let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let taskAll = self.loadFromJSONFilesOfDirectory(url: documentsURL) as! [Task]
        
        for task in taskAll {
            self.savedTask.append(task) }
        
    }
    
    func removeTask() {
        
        let fileName =  "task.json"
            
        if let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    @discardableResult func swap(item: Task, target: Task) -> Bool {
        
        guard let index = Schedule.shared.savedTask.compactMap({ $0.eventTask + $0.timeStamp }).firstIndex(of: item.eventTask + item.timeStamp ),  let targetIndex = Schedule.shared.savedTask.compactMap({ $0.eventTask + $0.timeStamp }).firstIndex(of: target.eventTask + target.timeStamp )  else { return false }
        
        let fileName = "task.json"
        Schedule.shared.savedTask.remove(at: index)
        Schedule.shared.savedTask.insert(item, at: targetIndex)
  
        if let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(Schedule.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    @discardableResult func removeSchedule(item: Task) -> Bool {
        
        guard let indexes = Schedule.shared.savedTask.compactMap({ $0.eventTask + $0.timeStamp }).firstIndex(of: item.eventTask + item.timeStamp ) else { return false }
        
        let fileName = "task.json"

       Schedule.shared.savedTask.remove(at: indexes)
  
        if let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(Schedule.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    @discardableResult func remove(item: EventTask) -> Bool {
        
        guard Schedule.shared.savedTask.compactMap({ $0.eventTask }).contains(item.taskTitle) else { return false }
        
        let fileName = "task.json"

        let indexes = Schedule.shared.savedTask.compactMap { $0.eventTask }.indexes(of: item.taskTitle)
        let flatArr = Schedule.shared.savedTask.enumerated().compactMap { indexes.contains($0.0) ? nil : $0.1 }
        Schedule.shared.savedTask = flatArr

        if let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(Schedule.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    @discardableResult func done(task: Task) -> Bool {
    
        guard Schedule.shared.savedTask.contains(task) else { return false }
        
        let fileName = "task.json"
        
        if let replace = Schedule.shared.savedTask.firstIndex(of: task) {
            Schedule.shared.savedTask[replace] = Task(date: task.date, labour: task.labour, eventTask: task.eventTask, timeStamp: task.timeStamp, done: !task.done)
            
            if let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                if let data = try? JSONEncoder().encode(Schedule.shared.savedTask) {
                    try? data.write(to: documentsURL)
                    return true
                }
            }
        }
        return false
    }
    
    
    @discardableResult func editEventTask(item: EventTask, oldItem : EventTask) -> Bool {
        
        guard Schedule.shared.savedTask.compactMap({ $0.eventTask }).contains(oldItem.taskTitle) else { return false }
        
        let fileName = "task.json"
        
        let indexes = Schedule.shared.savedTask.compactMap { $0.eventTask }.indexes(of: oldItem.taskTitle)
        let flatArr = Schedule.shared.savedTask.enumerated().compactMap { indexes.contains($0.0) ? Task(date: $0.1.date, labour: $0.1.labour, eventTask: item.taskTitle, timeStamp: $0.1.timeStamp, done: $0.1.done) : $0.1 }
       
        Schedule.shared.savedTask = flatArr

        if let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(Schedule.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    @discardableResult func save(task: Task) -> Bool {
    
        guard !Schedule.shared.savedTask.contains(task) else { return false }
        
        let fileName = "task.json"
        Schedule.shared.savedTask.append(task)
  
        if let documentsURL = Schedule.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(Schedule.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    private func loadFromJSONFilesOfDirectory(url contentURL: URL?) -> Any {
        
        if let validURL = contentURL,
           let contentOfFilesPath = (try? Schedule.fileManager.contentsOfDirectory(at: validURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) {
            
            for url in contentOfFilesPath where url.lastPathComponent == "task.json" {
                do {
                    let data = try Data(contentsOf: url)
                    let task = try JSONDecoder().decode([Task].self, from: data)
                    return task
                    
                } catch {
                    print("Failed to write JSON data: \(error.localizedDescription)")
                }
            }
        }
        return []
    }
}
