//
//  EventTask.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 2/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxDataSources

struct EventTask: Codable {
    let manDay : String
    let taskTitle: String
    let timeStamp: String
}

extension EventTask: Hashable {
    static func == (lhs: EventTask, rhs: EventTask) -> Bool {
        return lhs.manDay == rhs.manDay &&
            lhs.taskTitle == rhs.taskTitle
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(manDay)
        hasher.combine(taskTitle)
    }
}

extension EventTask: IdentifiableType {
    var identity: String {
        return self.taskTitle + self.timeStamp
    }
    
    typealias Identity = String
}


class EventTasks {
    
    static let shared = EventTasks()
    static let fileManager = FileManager.default
    var savedTask: [EventTask] = []
    
    func loadTask()  {

        let documentsURL = EventTasks.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let taskAll = self.loadFromJSONFilesOfDirectory(url: documentsURL) as! [EventTask]
        
        for task in taskAll {
            self.savedTask.append(task) }
        
    }
    
    func removeTask() {
        
        let fileName =  "eventtask.json"
            
        if let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    @discardableResult func swap(index: Int, target: Int, item: EventTask) -> Bool {
        
        guard target < EventTasks.shared.savedTask.count else { return false }
        
        let fileName = "eventtask.json"
        EventTasks.shared.savedTask.remove(at: index)
        EventTasks.shared.savedTask.insert(item, at: target)
  
        if let documentsURL = EventTasks.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(EventTasks.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    @discardableResult func remove(index: Int) -> Bool {
        
        guard index < EventTasks.shared.savedTask.count else { return false }
        
        let fileName = "eventtask.json"
        EventTasks.shared.savedTask.remove(at: index)
  
        if let documentsURL = EventTasks.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(EventTasks.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    
    @discardableResult func edit(newTask: EventTask, task: EventTask) -> Bool {
    
        guard EventTasks.shared.savedTask.contains(task) else { return false }
        
        let fileName = "eventtask.json"
        
        if let replace = EventTasks.shared.savedTask.firstIndex(of: task) {
            EventTasks.shared.savedTask[replace] = newTask
            
            if task.taskTitle != newTask.taskTitle {
                Schedule.shared.editEventTask(item: newTask, oldItem: task)
            }
            
            if let documentsURL = EventTasks.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                if let data = try? JSONEncoder().encode(EventTasks.shared.savedTask) {
                    try? data.write(to: documentsURL)
                    return true
                }
            }
        }
        return false
    }
    
    @discardableResult func save(task: EventTask) -> Bool {
    
        guard !EventTasks.shared.savedTask.contains(task) else { return false }
        
        let fileName = "eventtask.json"
        EventTasks.shared.savedTask.append(task)
  
        if let documentsURL = EventTasks.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
            if let data = try? JSONEncoder().encode(EventTasks.shared.savedTask) {
                try? data.write(to: documentsURL)
                return true
            }
        }
        return false
    }
    
    private func loadFromJSONFilesOfDirectory(url contentURL: URL?) -> Any {
        
        if let validURL = contentURL,
           let contentOfFilesPath = (try? EventTasks.fileManager.contentsOfDirectory(at: validURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) {
            
            for url in contentOfFilesPath where url.lastPathComponent == "eventtask.json" {
                do {
                    let data = try Data(contentsOf: url)
                    let task = try JSONDecoder().decode([EventTask].self, from: data)
                    return task
                    
                } catch {
                    print("Failed to write JSON data: \(error.localizedDescription)")
                }
            }
        }
        return []
    }
}
