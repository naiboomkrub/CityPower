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


struct ImagePosition: Codable {
    var x: Double {
        didSet {
            positionFloatX = CGFloat(oldValue)
        }
    }
    var y: Double {
        didSet {
            positionFloatY = CGFloat(oldValue)
        }
    }
    
    var defectPosition: CGPoint? {
        if let x = positionFloatX, let y = positionFloatY {
            return CGPoint(x: x, y: y)
        }
        return nil
    }
    
    var positionFloatX: CGFloat?
    var positionFloatY: CGFloat?
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
        self.positionFloatX = CGFloat(x)
        self.positionFloatY = CGFloat(y)
    }
    
    var dictionary: [String: Any] {
      return [
        "x": x,
        "y": y,
      ]
    }
    
    init?(dictionary: [String : Any]) {
        guard let x = dictionary["x"] as? Double,
            let y = dictionary["y"] as? Double else { return nil }
        
        self.init(x: x, y: y)
    }
}

extension ImagePosition: Hashable {
    static func == (lhs: ImagePosition, rhs: ImagePosition) -> Bool {
        return lhs.x == rhs.x &&
            lhs.y == rhs.y
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}


struct DefectGroup: Codable {
    let planTitle : String
    let timeStamp: String
    let planUrl: String
    let defectPosition: [ImagePosition]
        
    var dictionary: [String: Any] {
      return [
        "planTitle": planTitle,
        "timeStamp": timeStamp,
        "planUrl": planUrl,
        "defectPosition": defectPosition,
      ]
    }
    
    init(planTitle: String, timeStamp: String, planUrl: String, defectPosition: [ImagePosition]) {
        self.planTitle = planTitle
        self.timeStamp = timeStamp
        self.planUrl = planUrl
        self.defectPosition = defectPosition
    }
    
    init?(dictionary: [String : Any]) {
        guard let planTitle = dictionary["planTitle"] as? String,
            let timeStamp = dictionary["timeStamp"] as? String,
            let planUrl = dictionary["planUrl"] as? String,
            let defectPosition = dictionary["defectPosition"] as? [[String: Any]] else { return nil }
        
        self.planTitle = planTitle
        self.timeStamp = timeStamp
        self.planUrl = planUrl
        self.defectPosition = defectPosition.map( {ImagePosition(x: $0["x"] as! Double, y: $0["y"] as! Double) } )
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
