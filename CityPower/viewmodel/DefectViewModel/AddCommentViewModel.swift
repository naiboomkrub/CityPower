//
//  AddCommentViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 15/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa

class AddCommentViewModel {
    
    enum Event {
        case Save
     }
    
    let events = PublishSubject<Event>()
    let commentTopic = BehaviorRelay(value: "")
    let commentBody = BehaviorRelay(value: "")
    let editComment = BehaviorRelay(value: [CommentStruct]())
    
    let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
        
    func saveComment() {
        
        let newValue = CommentStruct(title: commentTopic.value,
                                     timeStamp: formatterDay.string(from: Date()), value: commentBody.value)
        if let docToEdit = editComment.value.first {
            DefectDetails.shared.update(docToEdit, newValue)
        } else {
            DefectDetails.shared.add(newValue)
        }
        events.onNext(.Save)
    }
}
