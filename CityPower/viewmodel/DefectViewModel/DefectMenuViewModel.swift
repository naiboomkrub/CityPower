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
    
        let defectGroup = DefectDetails.shared.savedGroup
        var sortFilter = Array(defectGroup.values).compactMap({ $0 })
        sortFilter.sort(by: { $0.planTitle < $1.planTitle })
        
        guard tempData != sortFilter else { return }
        
        tempData = sortFilter
        dataSource.accept(tempData)
    }
    
    func removeData(index: IndexPath) {
        
        var newValue = dataSource.value
        newValue.remove(at: index.row)
        dataSource.accept(newValue)
    }
    
    func selectedArea() {
        events.onNext(.SelectArea)
    }
    
    func addPlan() {
        events.onNext(.AddPlan)
    }
}
