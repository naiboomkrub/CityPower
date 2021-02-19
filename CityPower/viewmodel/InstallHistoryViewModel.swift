//
//  InstallHistoryViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 12/1/2564 BE.
//  Copyright © 2564 City Power. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa


class InstallHistoryViewModel {
    
    enum Event {
       case Data
     }
    
    let events = PublishSubject<Event>()
    let selectHistoryTitle = BehaviorRelay(value: "")
    let machineLabel = BehaviorRelay(value: "")
    let dataView1 = BehaviorRelay(value: [ContentStruct]())
    let dataView2 = BehaviorRelay(value: [ContentStruct]())
    
    let installHistory = BehaviorRelay(value: InstallHistory(machineLabel: "", data1: [ContentStruct](), data2: [ContentStruct](), timeStamp: "", topic: ""))
    
    var dataSource = BehaviorRelay<[InstallHistory]>(value: [])
    var tempData: [InstallHistory] = []
    
    func loadHistory() {
        
        tempData.removeAll()
            
        let histories: [InstallHistory] = InstallHistories.shared.savedTask
            
        for history in histories {
            tempData.append(history)
        }
        
        tempData =  tempData.unique(for:  \.self)
        dataSource.accept(tempData)
        
    }
    
    init() {    }
    
    func selectData(_ history: InstallHistory) {
        installHistory.accept(history)
        events.onNext(.Data)
      }
    
    func swapData(index: IndexPath, insertIndex: IndexPath, element: InstallHistory) {
          
        InstallHistories.shared.swap(index: index.row, target: insertIndex.row, item: element)

        var newValue = dataSource.value
        newValue.remove(at: index.row)
        newValue.insert(element, at: insertIndex.row)
        dataSource.accept(newValue)
    }
            
    func removeData(index: IndexPath) {
        
        var newValue = dataSource.value
        InstallHistories.shared.remove(index: index.row)
        newValue.remove(at: index.row)
        dataSource.accept(newValue)
    }
}
