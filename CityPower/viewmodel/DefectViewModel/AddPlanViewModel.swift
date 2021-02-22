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
import Firebase

class AddPlanViewModel {
    
    enum Event {
        case Save
     }
    
    let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
    
    private var ref: CollectionReference? = nil
    
    let db = Firestore.firestore()
    
    let events = PublishSubject<Event>()
    let defectDate = BehaviorRelay(value: "")
    let planName = BehaviorRelay(value: "")
    let imageLink = BehaviorRelay(value: "")
    
    init() {
        defectDate.accept(formatterDay.string(from: Date()))
    }
    
    func savePlan() {
        
        let planStruct = DefectGroup(planTitle: planName.value, timeStamp: formatterDay.string(from: Date()), planUrl: imageLink.value, defectPosition: [])
                
        do {
            let jsonData = try planStruct.jsonData()
            let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            guard let dictionary = json as? [String : Any] else { return }
  
            db.collection("plan").document("site").collection("currentSite").addDocument(data: dictionary) { [weak self] err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    self?.events.onNext(.Save)
                }
            }

        } catch {
            print("Failed to write JSON data: \(error.localizedDescription)")
        }
    }
}
