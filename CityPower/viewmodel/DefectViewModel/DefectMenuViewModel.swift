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


struct DefectGroup: Codable {
    let planTitle : String
    let timeStamp: String
    let planUrl: String
    
    var dictionary: [String: Any] {
      return [
        "planTitle": planTitle,
        "timeStamp": timeStamp,
        "planUrl": planUrl,
      ]
    }
    
    init(planTitle: String, timeStamp: String, planUrl: String) {
        self.planTitle = planTitle
        self.timeStamp = timeStamp
        self.planUrl = planUrl
    }
    
    init?(dictionary: [String : Any]) {
        guard let planTitle = dictionary["planTitle"] as? String,
            let timeStamp = dictionary["timeStamp"] as? String,
            let planUrl = dictionary["planUrl"] as? String else { return nil }
        
        self.planTitle = planTitle
        self.timeStamp = timeStamp
        self.planUrl = planUrl
    }
}

extension DefectGroup: Hashable {
    static func == (lhs: DefectGroup, rhs: DefectGroup) -> Bool {
        return lhs.planTitle == rhs.planTitle &&
            lhs.timeStamp == rhs.timeStamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(planTitle)
        hasher.combine(timeStamp)
    }
}

extension DefectGroup: IdentifiableType {
    var identity: String {
        return self.planTitle + self.timeStamp
    }
    
    typealias Identity = String
}


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
    
    func selectedArea() {
        events.onNext(.SelectArea)
    }
    
    func addPlan() {
        events.onNext(.AddPlan)
    }
}
