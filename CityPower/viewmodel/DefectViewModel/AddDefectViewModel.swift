//
//  AddDefectViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 10/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase

class AddDefectViewModel {
    
    enum Event {
        case Save
        case AddLocation
     }
    
    let events = PublishSubject<Event>()
    let defectDate = BehaviorRelay(value: "")
    let dueDate = BehaviorRelay(value: "")
    let defectTitle = BehaviorRelay(value: "")
    let resultPosition = BehaviorRelay(value: [CGPoint(), ""])
    let systemChose = BehaviorRelay(value: "")
    
    let db = Firestore.firestore()
    
    let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
    
    init() {
        defectDate.accept(formatterDay.string(from: Date()))
    }
    
    func saveDefect() {
        
        if let position = resultPosition.value[0] as? CGPoint, let numberTag = resultPosition.value[1] as? String {
        
            let dataStruct = DefectDetail(defectNumber: numberTag, defectTitle: defectTitle.value, defectImage: [], defectComment: [], finish: false, system: systemChose.value, timeStamp: defectDate.value, dueDate: dueDate.value, positionX: Double(position.x), positionY: Double(position.y))
            
            do {
                let jsonData = try dataStruct.jsonData()
                let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                
                guard let dictionary = json as? [String : Any], let ref = DefectDetails.shared.ref else { return }
                
                ref.addDocument(data: dictionary) { [weak self] err in
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
    
    func addLocation() {
        events.onNext(.AddLocation)
      }
}
