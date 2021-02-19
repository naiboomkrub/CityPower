//
//  DefectDetailViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import CardParts

class DefectDetailViewModel {
    
    enum Event {
        case photoEdit
        case addComment
        case doneDefect
     }
    
    var tempData: [CommentStruct] = []
    var tempPhoto: [ImageStruct] = []
    
    let photos = BehaviorRelay(value: [ImageSource]())
    let commentData = BehaviorRelay(value: [CommentStruct]())
    let photoData = BehaviorRelay(value: [ImageStruct]())
    let editComment = BehaviorRelay(value: [CommentStruct]())
    
    let imageName = BehaviorRelay(value: "")
    let dueDate = BehaviorRelay(value: "Due : Today")
    let createDate = BehaviorRelay(value: "Create: Today")
    let title = BehaviorRelay(value: "Defect Title")
    let state = BehaviorRelay(value: CardState.hasData)
    let photoState = BehaviorRelay(value: CardState.hasData)
    let positionDefect = BehaviorRelay(value: [CGPoint]())
    
    let events = PublishSubject<Event>()
    
    let formatter: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy-MM-dd"
         return formatter
     }()
    
    init() {
        
        DefectDetails.shared.updateComment = reloadComment
        DefectDetails.shared.updatePicture = reloadPhoto
    }
    
    func reloadComment() {
        
        tempData.removeAll()
        let defectList = DefectDetails.shared.savedComment
        
        for item in defectList {
            if let item = item {
                tempData.append(item)
            }
        }
        tempData = tempData.unique(for:  \.self)
        commentData.accept(tempData)
        
        if tempData.isEmpty {
            state.accept(.empty)
        } else {
            state.accept(.hasData)
        }
    }
    
    func reloadPhoto() {
        
        tempPhoto.removeAll()
        let defectList = DefectDetails.shared.savedPicture
        
        for item in defectList {
            if let item = item {
                tempPhoto.append(item)
            }
        }
        tempPhoto = tempPhoto.unique(for:  \.self)
        photoData.accept(tempPhoto)
        
        if tempPhoto.isEmpty {
            photoState.accept(.empty)
        } else {
            photoState.accept(.hasData)
        }
    }
    
    func photoEdit() {
        events.onNext(.photoEdit)
    }
    
    func doneDefect() {
        events.onNext(.doneDefect)
    }
    
    func removeComment(_ model: CommentStruct) {
        DefectDetails.shared.remove(model)
    }
    
    func editComment(_ model: [CommentStruct]) {
        editComment.accept(model)
        events.onNext(.addComment)
    }
    
    func addComment() {
        editComment.accept([])
        events.onNext(.addComment)
    }
    
    func removePhoto(_ model: ImageStruct) {
        DefectDetails.shared.remove(model)
    }
        
    func addPhoto(_ urlPhoto: String, _ fileName: String) {
        let newPhoto = ImageStruct(image: urlPhoto, timeStamp: formatter.string(from: Date()), fileName: fileName)
        DefectDetails.shared.add(newPhoto)
    }
}

