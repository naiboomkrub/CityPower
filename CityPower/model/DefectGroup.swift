//
//  DefectGroup.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 23/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxDataSources

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
    
    var pointNum: String
    var system: String
    var selected: Bool
    var status: String
    
    var defectPosition: CGPoint? {
        if let x = positionFloatX, let y = positionFloatY {
            return CGPoint(x: x, y: y)
        }
        return nil
    }
    
    var positionFloatX: CGFloat?
    var positionFloatY: CGFloat?
    
    init(x: Double, y: Double, pointNum: String, system: String, status: String, selected: Bool) {
        self.x = x
        self.y = y
        self.pointNum = pointNum
        self.positionFloatX = CGFloat(x)
        self.positionFloatY = CGFloat(y)
        self.system = system
        self.status = status
        self.selected = selected
    }
    
    var dictionary: [String: Any] {
      return [
        "x": x,
        "y": y,
        "pointNum": pointNum,
        "system": system,
        "status": status,
        "selected": selected,
      ]
    }
    
    init?(dictionary: [String : Any]) {
        guard let x = dictionary["x"] as? Double,
              let y = dictionary["y"] as? Double,
              let pointNum = dictionary["pointNum"] as? String,
              let system = dictionary["system"] as? String,
              let status = dictionary["status"] as? String,
              let selected = dictionary["selected"] as? Bool else { return nil }
        
        self.init(x: x, y: y, pointNum: pointNum, system: system, status: status, selected: selected)
    }
}

extension ImagePosition: Hashable {
    static func == (lhs: ImagePosition, rhs: ImagePosition) -> Bool {
        return abs(lhs.x - rhs.x) < 1 &&
            abs(lhs.y - rhs.y) < 1
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
    let numberOfStart: Int64
    let numberOfOnGoing: Int64
    let numberOfFinish: Int64
    let defectDate: [String: String]
    let defectPosition: [ImagePosition]
        
    var dictionary: [String: Any] {
      return [
        "planTitle": planTitle,
        "timeStamp": timeStamp,
        "planUrl": planUrl,
        "numberOfStart": numberOfStart,
        "numberOfOnGoing": numberOfOnGoing,
        "numberOfFinish": numberOfFinish,
        "defectDate": defectDate,
        "defectPosition": defectPosition,
      ]
    }
    
    init(planTitle: String, timeStamp: String, planUrl: String, numberOfStart: Int64, numberOfOnGoing: Int64, numberOfFinish: Int64, defectDate: [String: String], defectPosition: [ImagePosition]) {
        self.planTitle = planTitle
        self.timeStamp = timeStamp
        self.planUrl = planUrl
        self.numberOfStart = numberOfStart
        self.numberOfFinish = numberOfFinish
        self.numberOfOnGoing = numberOfOnGoing
        self.defectDate = defectDate
        self.defectPosition = defectPosition
    }
    
    init?(dictionary: [String : Any]) {
        guard let planTitle = dictionary["planTitle"] as? String,
            let timeStamp = dictionary["timeStamp"] as? String,
            let planUrl = dictionary["planUrl"] as? String,
            let numberOfStart = dictionary["numberOfStart"] as? Int64,
            let numberOfOnGoing = dictionary["numberOfOnGoing"] as? Int64,
            let numberOfFinish = dictionary["numberOfFinish"] as? Int64,
            let defectDate = dictionary["defectDate"] as? [String: String],
            let defectPosition = dictionary["defectPosition"] as? [[String: Any]] else { return nil }
        
        self.planTitle = planTitle
        self.timeStamp = timeStamp
        self.planUrl = planUrl
        self.numberOfStart = numberOfStart
        self.numberOfFinish = numberOfFinish
        self.numberOfOnGoing = numberOfOnGoing
        self.defectDate = defectDate
        self.defectPosition = defectPosition.map( {ImagePosition(x: $0["x"] as! Double, y: $0["y"] as! Double, pointNum: $0["pointNum"] as! String, system: $0["system"] as! String, status: $0["status"] as! String, selected: $0["selected"] as! Bool) } )
    }
}

extension DefectGroup: Hashable {
    static func == (lhs: DefectGroup, rhs: DefectGroup) -> Bool {
        return lhs.planTitle == rhs.planTitle &&
            lhs.timeStamp == rhs.timeStamp &&
            lhs.numberOfStart == rhs.numberOfStart &&
            lhs.numberOfOnGoing == rhs.numberOfOnGoing &&
            lhs.numberOfFinish == rhs.numberOfFinish
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(planTitle)
        hasher.combine(timeStamp)
        hasher.combine(numberOfStart)
        hasher.combine(numberOfOnGoing)
        hasher.combine(numberOfFinish)
    }
}

extension DefectGroup: IdentifiableType {
    var identity: String {
        return self.planTitle + self.timeStamp
    }
    
    typealias Identity = String
}
