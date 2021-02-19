//
//  AddDateViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 3/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class AddDateViewModel {
    
    enum Event {
        case Save
        case AddTask
     }
    
    let events = PublishSubject<Event>()
    let taskDate = BehaviorRelay(value: "")
    let timeStamp = BehaviorRelay(value: "")
    let taskSelected = BehaviorRelay(value: "Add Task")
    let manPower = BehaviorRelay(value: "")
    
    let formatterHour: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter
     }()
    
    init(date: String) { taskDate.accept(date) }
    
    func saveDate() {
        Schedule.shared.save(task: Task(date: taskDate.value, labour: manPower.value, eventTask: taskSelected.value, timeStamp: formatterHour.string(from: Date()), done: false))
        events.onNext(.Save)
      }
    
    func addTask() {
        events.onNext(.AddTask)
      }
}
