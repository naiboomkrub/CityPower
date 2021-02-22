//
//  SelectPositionViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 10/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SelectPositionViewModel {
    
    enum Event {
       case SavePosition
     }

    let events = PublishSubject<Event>()
    
    let imageName = BehaviorRelay(value: "")
    let positionDefect = BehaviorRelay<[String: CGPoint]>(value: [:])
    
    let positionSelected = BehaviorRelay(value: [CGPoint(), ""])
    
    func savePosition() {
        events.onNext(.SavePosition)
    }
    
}
