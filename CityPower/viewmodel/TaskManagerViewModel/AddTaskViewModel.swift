//
//  AddTaskViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 2/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class AddTaskViewModel {
    
    enum Event {
        case Save
     }
    
    let events = PublishSubject<Event>()
    let taskDesc = BehaviorRelay(value: "")
    let manDay = BehaviorRelay(value: "")
    
    var editValue = false
    var firstEvent: EventTask!
    
    let formatterHour: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter
     }()
    
    init(eventTask: EventTask, edit: Bool) {
        taskDesc.accept(eventTask.taskTitle)
        manDay.accept(eventTask.manDay)
        self.editValue = edit
        self.firstEvent = eventTask
    }
    
    func saveTask() {
        guard !(taskDesc.value == firstEvent.taskTitle && manDay.value == firstEvent.manDay) else { return }
        
        if self.editValue {
            EventTasks.shared.edit(newTask: EventTask(manDay: manDay.value, taskTitle: taskDesc.value, timeStamp: formatterHour.string(from: Date())), task: firstEvent)
            events.onNext(.Save)
        
        } else {
            EventTasks.shared.save(task: EventTask(manDay: manDay.value, taskTitle: taskDesc.value, timeStamp: formatterHour.string(from: Date())))
            events.onNext(.Save)
        }
    }
    
    func changeTask(_ taskDes: String) {
        taskDesc.accept(taskDes)
    }
    
    func changeManDay(_ taskManday: String) {
        manDay.accept(taskManday)
    }
    
}
