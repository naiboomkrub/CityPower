//
//  DefectMenuViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxDataSources
import RxSwift
import RxCocoa

class DefectMenuViewModel {
    
    enum Event {
        case SelectArea
        case AddPlan
     }
    
    var dataSource = BehaviorRelay<[DefectGroup]>(value: [])
    var tempData: [DefectGroup] = []
    var photos: [URL] = []
    
    let indexRow = BehaviorRelay(value: 0)
    let planDetail = BehaviorRelay(value: "")
    let events = PublishSubject<Event>()
    let formatterHour: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter
     }()
    
    init() {
        
        DefectDetails.shared.updateGroup = reloadData
    }
    
    func reloadData() {
        
        tempData.removeAll()
        
        let defectGroup = DefectDetails.shared.savedGroup
        
        for item in defectGroup {
            if let item = item {
                tempData.append(item)
            }
        }
        
        tempData = tempData.unique(for:  \.self)
        dataSource.accept(tempData)
    }
    
    func swapData(index: IndexPath, insertIndex: IndexPath, element: DefectGroup) {
          
        var newValue = dataSource.value
        newValue.remove(at: index.row)
        newValue.insert(element, at: insertIndex.row)
        dataSource.accept(newValue)
    }
    
    func removeData(index: IndexPath) {
        
        var newValue = dataSource.value
        newValue.remove(at: index.row)
        dataSource.accept(newValue)
    }
    
    func selectedArea(_ index: Int) {
        indexRow.accept(index)
        events.onNext(.SelectArea)
    }
    
    func addPlan() {
        events.onNext(.AddPlan)
    }
}
