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
    var guardData: [DefectGroup?] = []
    
    let durationData = BehaviorRelay(value: [CountCell]())
    let statusData = BehaviorRelay(value: [CountCell]())
    let totalDefect = BehaviorRelay(value: "0")
    let loadStatus = BehaviorRelay(value: false)
    
    let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
    
    let events = PublishSubject<Event>()
    
    init() {
        
        DefectDetails.shared.updateStatus = reloadStatus
        
        let allStatus = [("Start", 0), ("Ongoing", 0), ("Complete", 0)]
        let allDuration = [("< 7 Days", 0), ("7 - 14 Days", 0),
                           ("15 - 30 Days", 0), ("> 30 Days", 0)]
        
        for (item, number) in allStatus {
            tempStatus.append(CountCell(label: item, count: "\(number)"))
        }
        for (item, number) in allDuration {
            tempDuration.append(CountCell(label: item, count: "\(number)"))
        }
        loadStatus.accept(true)
        statusData.accept(tempStatus)
        durationData.accept(tempDuration)
    }
    
    func reloadStatus() {
        
        guard guardData != DefectDetails.shared.savedGroup else { return }
        
        tempStatus.removeAll()
        tempDuration.removeAll()
        
        var totalStart: Int64 = 0
        var totalOngoing: Int64 = 0
        var totalComplete: Int64 = 0
                
        var dateSeven: Int64 = 0
        var dateFifteen: Int64 = 0
        var dateThirty: Int64 = 0
        var dateElse: Int64 = 0
            
        DefectDetails.shared.savedGroup.forEach({
            if let numStart = $0?.numberOfStart,
               let numOnGoing = $0?.numberOfOnGoing,
               let numFinish = $0?.numberOfFinish,
               let dateAll = $0?.defectDate.values {
                totalStart = totalStart + numStart
                totalOngoing = totalOngoing + numOnGoing
                totalComplete = totalComplete + numFinish
                
                for date in dateAll {
                    let date = String(date.suffix(10))
                    
                    if let formatDay = formatterDay.date(from: date) {
                        let delta = formatDay - Date()
                        if delta < 604800 {
                            dateSeven += 1
                        } else if delta < 1296000 {
                            dateFifteen += 1
                        } else if delta < 2592000 {
                            dateThirty += 1
                        } else {
                            dateElse += 1
                        }
                    }
                }
            }
        })
        totalDefect.accept("\(totalStart + totalComplete + totalOngoing)")
        loadStatus.accept(false)
        
        let allStatus = [("Start", totalStart), ("Ongoing", totalOngoing), ("Complete", totalComplete)]
        let allDuration = [("< 7 Days", dateSeven),
                           ("7 - 14 Days", dateFifteen),
                           ("15 - 30 Days", dateThirty),
                           ("> 30 Days", dateElse)]
        
        for (item, number) in allStatus {
            tempStatus.append(CountCell(label: item, count: "\(number)"))
        }
        for (item, number) in allDuration {
            tempDuration.append(CountCell(label: item, count: "\(number)"))
        }
        
        guardData = DefectDetails.shared.savedGroup
        
        statusData.accept(tempStatus)
        durationData.accept(tempDuration)
    }
    
    func selectDefect() {
        events.onNext(.selectDefect)
    }
}


extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}
