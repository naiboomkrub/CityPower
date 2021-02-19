//
//  ScheduleViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources


class ScheduleViewModel {
    
    enum Event {
        case AddTask
        case AddDate
        case EditTask
     }
    
    let events = PublishSubject<Event>()
    let date = BehaviorRelay(value: "")
    
    var dataSource = BehaviorRelay<[EventTask]>(value: [])
    var scheduleSource = BehaviorRelay<[Task]>(value: [])
    var editInfo = BehaviorRelay<[EventTask]>(value: [])

    var currentDate = ""
    var tempData: [Task] = []
    
    init() {   }
    
    func changeDate() {
        
        tempData.removeAll()
            
        let allTask: [Task] = Schedule.shared.savedTask
            
        for task in allTask {
            if task.date == date.value {
                tempData.append(task) }
        }
        
        tempData =  tempData.unique(for:  \.self)
        
        currentDate = date.value
        scheduleSource.accept(tempData)
        
    }
    
    func editTask(taskClick: [EventTask]) {
        
        editInfo.accept(taskClick)
        events.onNext(.EditTask)

    }
    
    func taskDone(taskClick: Task) {
        
        Schedule.shared.done(task: taskClick)
        changeDate()
    }
    
    func reloadData() {
        
        dataSource.accept(EventTasks.shared.savedTask)

    }
    
    func addTask() {
          
        events.onNext(.AddTask)
      
    }
    
    
    func addDate() {
          
        events.onNext(.AddDate)
      
    }
    
    func swapData(index: IndexPath, insertIndex: IndexPath, element: EventTask) {
          
        EventTasks.shared.swap(index: index.row, target: insertIndex.row, item: element)

        var newValue = dataSource.value
        newValue.remove(at: index.row)
        newValue.insert(element, at: insertIndex.row)
        dataSource.accept(newValue)
    }
    
    func swapSchedule(index: IndexPath, insertIndex: IndexPath, element: Task) {
          
        var newValue = scheduleSource.value
        Schedule.shared.swap(item: newValue[index.row], target: newValue[insertIndex.row])
        newValue.remove(at: index.row)
        newValue.insert(element, at: insertIndex.row)
        scheduleSource.accept(newValue)
    }
        
    func removeData(index: IndexPath) {
          
        EventTasks.shared.remove(index: index.row)
        
        let indexes = scheduleSource.value.compactMap {$0.eventTask }.indexes(of: dataSource.value[index.row].taskTitle)
        let flatArr = scheduleSource.value.enumerated().compactMap { indexes.contains($0.0) ? nil : $0.1 }
        
        var newValue = dataSource.value
        Schedule.shared.remove(item: newValue[index.row])
        newValue.remove(at: index.row)
        tempData = flatArr
        dataSource.accept(newValue)
        scheduleSource.accept(flatArr)
    }
    
    func removeSchedule(index: IndexPath) {
        
        var newValue = scheduleSource.value
        Schedule.shared.removeSchedule(item: newValue[index.row])
        newValue.remove(at: index.row)
        tempData = newValue
        scheduleSource.accept(newValue)
    }
}


extension Array where Element: Equatable {
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}

extension Sequence {

    func unique<T: Hashable>(for keyPath: KeyPath<Element, T>) -> [Element] {
        var unique = Set<T>()
        return filter { unique.insert($0[keyPath: keyPath]).inserted }
    }
}
