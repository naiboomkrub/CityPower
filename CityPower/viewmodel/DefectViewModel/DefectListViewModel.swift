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

enum PointState {
    case All
    case Empty
    case NotChose
    case General
    case Electrical
    case Sanitary
    case Mechanical
 }

class DefectListViewModel {
    
    enum Event {
        case SelectDefect
        case AddDefect
     }
    
    var tempData = [DefectDetail]()
    var tempImagePoint = [ImagePosition]()
    var filter = "General"
    
    let statusFilter = BehaviorRelay(value: "")
    let imageName = BehaviorRelay(value: "")
    let progressSpin = BehaviorRelay(value: true)
    let positionTag = BehaviorRelay(value: [ImagePosition]())
    let defectDetailModel = BehaviorRelay(value: [DefectDetail]())
    let dataSource = BehaviorRelay(value: [DefectDetail]())
    let imagePoint = BehaviorRelay(value: [ImagePosition]())
    let temFilter = BehaviorRelay(value: PointState.All)
    
    let events = PublishSubject<Event>()
    
    let formatterHour: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter
     }()
    
    init() {
        DefectDetails.shared.updateCell = reloadData
        DefectDetails.shared.layoutPoint = reloadImagePoint
    }
    
    func reloadData() {
                   
        let defectList = DefectDetails.shared.savedDefect
        var sortFilter = Array(defectList.values).filter({ $0?.system == filter }).compactMap({ $0 })
        sortFilter.sort(by: { $0.defectNumber < $1.defectNumber })
        
        progressSpin.accept(false)
        
        guard tempData != sortFilter else { return }
        
        tempData = sortFilter
        dataSource.accept(tempData)
    }
    
    func reloadImagePoint() {
                        
        tempImagePoint.removeAll()
        
        let imagePointAll = DefectDetails.shared.savedPosition
        
        for item in imagePointAll {
            if let item = item {
                tempImagePoint.append(item)
            }
        }
        imagePoint.accept(tempImagePoint)
    }
    
    func removeData(index: IndexPath) {
        
        var newValue = dataSource.value
        newValue.remove(at: index.row)
        dataSource.accept(newValue)
    }
    
    func selectedDefect(_ model: DefectDetail) {
        defectDetailModel.accept([model])
        events.onNext(.SelectDefect)
    }
    
    func addDefect() {
        events.onNext(.AddDefect)
    }
}
