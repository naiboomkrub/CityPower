//
//  SiteDetailViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import CardParts
import RxDataSources

struct CountCell: Codable {
    let label : String
    let count: String
}

extension CountCell: Hashable {
    static func == (lhs: CountCell, rhs: CountCell) -> Bool {
        return lhs.label == rhs.label &&
            lhs.count == rhs.count
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(count)
    }
}

extension CountCell: IdentifiableType {
    var identity: String {
        return self.label + self.count
    }
    
    typealias Identity = String
}


class SiteDetailViewModel {
    
    enum Event {
        case selectDefect
        case selectUnit
        case selectArea
     }
    
    var tempDuration: [CountCell] = []
    var tempStatus: [CountCell] = []
    
    let durationData = BehaviorRelay(value: [CountCell]())
    let statusData = BehaviorRelay(value: [CountCell]())
    let totalDefect = BehaviorRelay(value: "0")
    
    let events = PublishSubject<Event>()
    
    init() {
        
//        DefectDetails.shared.updateComment = reloadComment
    }
    
    func reloadStatus() {
        
        tempStatus.removeAll()
        
        let allStatus = ["Start", "Ongoing", "Complete"]
        
        for item in allStatus {
            let number = "0"
            tempStatus.append(CountCell(label: item, count: number))
        }
        tempStatus = tempStatus.unique(for:  \.self)
        statusData.accept(tempStatus)
    }
    
    func reloadDuration() {
        
        tempDuration.removeAll()
        
        let allDuration = ["< 7 Days", "7 - 14 Days", "15 - 30 Days", "> 30 Days"]
        
        for item in allDuration {
            let number = "0"
            tempDuration.append(CountCell(label: item, count: number))
        }
        tempDuration = tempDuration.unique(for:  \.self)
        durationData.accept(tempDuration)
    }
    
    func selectDefect() {
        events.onNext(.selectDefect)
    }
}
