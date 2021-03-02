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
    let resultPosition = BehaviorRelay(value: [ImagePosition]())
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
        
        if let imageModel = resultPosition.value.first, let position = imageModel.defectPosition {
                        
            let dataStruct = DefectDetail(defectNumber: imageModel.pointNum, defectTitle: defectTitle.value, defectImage: [], defectComment: [], finish: false, system: systemChose.value, timeStamp: defectDate.value, dueDate: dueDate.value, positionX: round(Double(position.x) * 1000) / 1000, positionY: round(Double(position.y) * 1000) / 1000)
            
            DefectDetails.shared
                .movePoint(ImagePosition(x: dataStruct.positionX,
                                         y: dataStruct.positionY, pointNum: dataStruct.defectNumber,
                                         system: "", selected: false),
                            ImagePosition(x: dataStruct.positionX,
                                          y: dataStruct.positionY, pointNum: dataStruct.defectNumber,
                                          system: dataStruct.system, selected: true))
            
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
