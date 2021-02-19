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
    
    private var ref: DocumentReference? = nil
    
    let events = PublishSubject<Event>()
    let defectDate = BehaviorRelay(value: "")
    let dueDate = BehaviorRelay(value: "")
    let defectTitle = BehaviorRelay(value: "")
    let resultPosition = BehaviorRelay(value: CGPoint())
    
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
        
        let imageStruct = DefectDetail(defectNumber: "BOOM", defectTitle: "BOOM", defectImage: [ImageStruct(image: "BOOM", timeStamp: "BOOM", fileName: "BOOM")], defectComment: [CommentStruct(title: "BOOM", timeStamp: "BOOM")], finish: false, system: "General", timeStamp: "BOOM", dueDate: "BOOM", positionX: 123, positionY: 123)
        
        do {
            let jsonData = try imageStruct.jsonData()
            let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            guard let dictionary = json as? [String : Any] else { return }
            
            ref = db.collection("defect").addDocument(data: dictionary) { [weak self] err in
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
    
    func addLocation() {
        events.onNext(.AddLocation)
      }
}
