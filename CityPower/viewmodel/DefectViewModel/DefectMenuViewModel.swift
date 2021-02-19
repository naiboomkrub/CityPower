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
    let defectTitle : String
    let defectDes: String
    let timeStamp: String
    let url: URL?
    
    init(defectTitle: String, defectDes: String, timeStamp: String, url: URL? = nil) {
        self.defectTitle = defectTitle
        self.defectDes = defectDes
        self.timeStamp = timeStamp
        self.url = url
    }
}

extension DefectGroup: Hashable {
    static func == (lhs: DefectGroup, rhs: DefectGroup) -> Bool {
        return lhs.defectDes == rhs.defectDes &&
            lhs.defectTitle == rhs.defectTitle
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(defectTitle)
        hasher.combine(defectDes)
    }
}

extension DefectGroup: IdentifiableType {
    var identity: String {
        return self.defectTitle + self.timeStamp
    }
    
    typealias Identity = String
}


class DefectMenuViewModel {
    
    enum Event {
        case SelectArea
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
        
        photos = demoPhotosURLs
    }
    
    func reloadData() {
        
        tempData.removeAll()
            
        //for url_ in photos {
       //     let allDefect: [DefectGroup] = [DefectGroup(defectTitle: "awdawd", defectDes: "wafawf", timeStamp: formatterHour.string(from: Date()))]
            
        for url_ in photos {
            tempData.append(DefectGroup(defectTitle: "awdawd", defectDes: "wafawf", timeStamp: formatterHour.string(from: Date()), url: url_))
        }
        
        //tempData =  tempData.unique(for:  \.self)
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
}
