//
//  SiteListViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxDataSources
import RxSwift
import RxCocoa

class SiteListViewModel {
    
    enum Event {
        case SelectSite
     }
    
    var dataSource = BehaviorRelay<[SiteGroup]>(value: [])
    var tempData: [SiteGroup] = []
    var photos: [URL] = []
    
    let siteName = BehaviorRelay(value: "")
    let events = PublishSubject<Event>()
    
    init() { DefectDetails.shared.updateSite = reloadData }
    
    func reloadData() {
        
        guard tempData.isEmpty else { return }

        let defectGroup = DefectDetails.shared.savedSite

        for item in defectGroup {
            if let item = item {
                tempData.append(item)
            }
        }

        tempData = tempData.unique(for:  \.self)
        dataSource.accept(tempData)
    }

    
    func selectedSite(_ model: SiteGroup) {
        DefectDetails.shared.selectedSite = model.name
        events.onNext(.SelectSite)
    }
}
