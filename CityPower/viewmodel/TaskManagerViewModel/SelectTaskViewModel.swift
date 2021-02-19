//
//  SelectTaskViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 4/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources


struct TaskSect {
    var header: String
}

typealias TaskSection = SectionModel<TaskViewSection, TaskViewItem>

enum TaskViewSection {
    case main(info: TaskSect)
}

enum TaskViewItem {
    case subject(info: EventTask)
}


class SelectTaskViewModel {
    
    enum Event {
       case EndContent
     }
    
    let events = PublishSubject<Event>()
    let taskSelected = BehaviorRelay(value: "")
    let sections = PublishSubject<[TaskSection]>()
  
    var tempData: [TaskViewItem] = []
    var allSection: [TaskSection] = []
    
    init() {   }
    
    func reloadData() {
        
        allSection.removeAll()
        tempData.removeAll()
        
        let allCategory: [EventTask] = EventTasks.shared.savedTask
        
        for category in allCategory {
            tempData.append(.subject(info: category))
        }
        
        allSection.append(TaskSection(model: .main(info: TaskSect(header: "Boom")), items: tempData))
        sections.onNext(allSection)
    }
    
}
