//
//  AddPlanViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 19/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class AddPlanViewModel {
    
    let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
    
    let defectDate = BehaviorRelay(value: "")
    
    init() {
        defectDate.accept(formatterDay.string(from: Date()))
    }
}
