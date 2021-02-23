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
    
    var defectPosition: CGPoint? {
        if let x = positionFloatX, let y = positionFloatY {
            return CGPoint(x: x, y: y)
        }
        return nil
    }
    
    var positionFloatX: CGFloat?
    var positionFloatY: CGFloat?
    
    init(x: Double, y: Double, pointNum: String) {
        self.x = x
        self.y = y
        self.pointNum = pointNum
        self.positionFloatX = CGFloat(x)
        self.positionFloatY = CGFloat(y)
    }
    
    var dictionary: [String: Any] {
      return [
        "x": x,
        "y": y,
        "pointNum": pointNum,
      ]
    }
    
    init?(dictionary: [String : Any]) {
        guard let x = dictionary["x"] as? Double,
              let y = dictionary["y"] as? Double,
              let pointNum = dictionary["pointNum"] as? String else { return nil }
        
        self.init(x: x, y: y, pointNum: pointNum)
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
        self.defectPosition = defectPosition.map( {ImagePosition(x: $0["x"] as! Double, y: $0["y"] as! Double, pointNum: $0["pointNum"] as! String) } )
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
