//
//  DefectListViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources

class DefectListViewModel {
    
    enum Event {
        case SelectDefect
        case AddDefect
     }
    
    var tempData = [DefectDetail]()
    var filter = "General"
    
    let imageName = BehaviorRelay(value: "")
    let progressSpin = BehaviorRelay(value: true)
    let indexRow = BehaviorRelay(value: 0)
    let positionTag = BehaviorRelay<[String: CGPoint]>(value: [:])
    let defectDetailModel = BehaviorRelay(value: [DefectDetail]())
    let dataSource = BehaviorRelay(value: [DefectDetail]())
    
    let events = PublishSubject<Event>()
    
    let formatterHour: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter
     }()
    
    init() {
        DefectDetails.shared.updateCell = reloadData
    }
    
    func reloadData() {
                        
        tempData.removeAll()
        
        let defectList = DefectDetails.shared.savedDefect
        
        for item in defectList {
            if let item = item, item.system == filter {
                tempData.append(item)
            }
        }
        
        tempData = tempData.unique(for:  \.self)
        dataSource.accept(tempData)
        progressSpin.accept(false)
    }
    
    
    func swapData(index: IndexPath, insertIndex: IndexPath, element: DefectDetail) {
          
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
    
    func selectedDefect(_ model: DefectDetail, _ index: IndexPath) {
        defectDetailModel.accept([model])
        indexRow.accept(index.row)
        events.onNext(.SelectDefect)
    }
    
    func addDefect() {
        events.onNext(.AddDefect)
    }
}
