//
//  MainMenuViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import CardParts

class MainMenuViewModel {
    
    let listData: BehaviorRelay<[Task]> = BehaviorRelay(value: [])
    let progressData = BehaviorRelay(value: Float())
    let state = BehaviorRelay(value: CardState.empty)
    
    let taskNumber = BehaviorRelay(value: "")
    let username = BehaviorRelay(value: "")
    let completed = BehaviorRelay(value: "")
    let incompleted = BehaviorRelay(value: "")
    
    
    init() {
        
        changeDate()
        username.accept(UserDefaultsManager.username)
    }
    
    var tempData: [Task] = []
    var progressPer = 0.0
    
    let formatter: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy-MM-dd"
         return formatter
     }()

    func changeDate() {
        
        tempData.removeAll()
        progressPer = 0.0
        
        let allTask: [Task] = Schedule.shared.savedTask
            
        for task in allTask {
            if task.date == formatter.string(from: Date()) {
                tempData.append(task)
                if task.done {
                    progressPer += 1.0
                }
            }
        }
        
        tempData =  tempData.unique(for:  \.self)
        progressPer = progressPer / Double(tempData.count)
        progressData.accept(Float(progressPer))
        listData.accept(tempData)
        
        if tempData.count > 0 {
            state.accept(.hasData)
            taskNumber.accept("\(Int(progressPer))  /  \(tempData.count)  Task Completed")
        } else {
            state.accept(.empty)
            taskNumber.accept("No Task")
        }
        
        completed.accept("Incompleted Install :   \(InstallHistories.shared.savedTask.count)")
        incompleted.accept("Completed Install :     \(InstallHistories.shared.savedTask.count)")
        
    }
    
    func taskDone(taskClick: Task) {
        
        Schedule.shared.done(task: taskClick)
        changeDate()
    }
}
