//
//  InstallContentViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift


struct ContentSect {
    var header: String
    var items: [ContentStruct]
    var collapsed: Bool
    
    init(header: String, items: [ContentStruct], collapsed: Bool = false) {
        self.header = header
        self.items = items
        self.collapsed = collapsed
    }
}


struct ContentStruct: Codable {
    var title: String
    var select: Bool
    var value: String
    
    init(title: String, select: Bool = false, value: String = "") {
        self.title = title
        self.select = select
        self.value = value
    }
}


class InstallContentViewModel {
    
    enum Event {
       case EndContent
     }
    
    let events = PublishSubject<Event>()
    let contentTitle = BehaviorRelay(value: "")
    let machineLabel = BehaviorRelay(value: "")
    
    let installHistory = BehaviorRelay(value: InstallHistory(machineLabel: "", data1: [ContentStruct](), data2: [ContentStruct](), timeStamp: "", topic: ""))
    
    var sections = [ContentSect]()
    var data1 = [ContentStruct]()
    var data2 = [ContentStruct]()
    
    var loadHistory = false
    
    init() {  }

    func saveTask(_ installHis : InstallHistory) {
        
        if self.loadHistory {
            InstallHistories.shared.edit(newTask: installHis, task: installHistory.value)
            events.onNext(.EndContent)
        
        } else {
            InstallHistories.shared.save(task: installHis)
            events.onNext(.EndContent)
        }
    }
        
    func reloadData() {
        
        if !loadHistory {
            
            machineLabel.accept("")
            switch contentTitle.value {
            case "Wiring":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Disconnect Equipment"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Flow"),
                            ContentStruct(title: "2. Load")]
            case "Wiring2":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Load Value")]
                data2 = [ContentStruct(title: "1. Voltage"),
                            ContentStruct(title: "2. Load")]
            case "Wiring3":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Disconnect Equipment"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Ampere"),
                            ContentStruct(title: "2. Load")]
            case "Piping":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Measure Value"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Flow"),
                            ContentStruct(title: "2. Differential Pressure"),
                            ContentStruct(title: "3. Load")]
            case "Piping2":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Swap Equipment"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Flow"),
                            ContentStruct(title: "2. Inertia")]
            case "Piping3":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Disconnect Equipment"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Flow"),
                            ContentStruct(title: "2. Load")]
            case "Installing":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Disconnect Equipment"),
                            ContentStruct(title: "4. Clear Value")]
                data2 = [ContentStruct(title: "1. Wattage"),
                            ContentStruct(title: "2. Load")]
            case "Installing2":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Disconnect Equipment"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Flow"),
                            ContentStruct(title: "2. Voltage")]
            case "Digging":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Clean Equipment")]
                data2 = [ContentStruct(title: "1. Width"),
                            ContentStruct(title: "2. Depth")]
            case "Digging2":
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Clean Equipment")]
                data2 = [ContentStruct(title: "1. Height"),
                            ContentStruct(title: "2. Load")]
            default:
                data1 = [ContentStruct(title: "1. General"),
                            ContentStruct(title: "2. Check Equipment"),
                            ContentStruct(title: "3. Disconnect Equipment"),
                            ContentStruct(title: "4. Load Value")]
                data2 = [ContentStruct(title: "1. Flow"),
                            ContentStruct(title: "2. Load")]
            }
            
            sections = [ContentSect(header: "Input Value", items: data1),
                        ContentSect(header: "Installation Procedure", items: data2)]
        }
        
        else {
            machineLabel.accept(installHistory.value.machineLabel)
            contentTitle.accept(installHistory.value.topic)
            
            sections = [ContentSect(header: "Input Value", items: installHistory.value.data1),
                        ContentSect(header: "Installation Procedure", items: installHistory.value.data2)]
        }
    }
}
