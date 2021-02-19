//
//  InstallationViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class InstallationViewModel {
    
    enum Event {
        case Content
        case History
     }
    
    let events = PublishSubject<Event>()
    let listData: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    let selectContentTitle = BehaviorRelay(value: "")
    
    let installMet: [String] = ["Wiring", "Piping", "Installing", "Digging", "Duct"]
    let installMet2: [String] = ["Wiring2", "Piping2", "Installing2", "Digging2", "Duct2", "Drilling"]
    let installMet3: [String] = ["Wiring3", "Piping3"]
    
    init() {
        
        listData.accept(installMet)
    }
    
    func selectPill() {
        listData.accept(installMet)
    }
    
    func selectPill2() {
        listData.accept(installMet2)
    }
    
    func selectPill3() {
        listData.accept(installMet3)
    }
    
    func selectContent() {
          
        events.onNext(.Content)
      }
    
    func selectHistory() {
          
        events.onNext(.History)
      }
}
