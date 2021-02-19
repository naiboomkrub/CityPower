//
//  DashBoardViewModel.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 26/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class DashBoardViewModel {
    
    enum Event {
        case Start
        case Select
        case User
        case Exit
     }
    
    let events = PublishSubject<Event>()
    
    let selectTopic = BehaviorRelay(value: "")
    let title = BehaviorRelay(value: "")
    let title2 = BehaviorRelay(value: "")
    let text = BehaviorRelay(value: "")
    let choiceNum = BehaviorRelay(value: Int())
    
    let colorGrad = BehaviorRelay(value: [UIColor()])
    
    func submit() {
        
        events.onNext(.Start)
    }
    
    func select() {
        
        events.onNext(.Select)
    }
    
    func user() {
        
        events.onNext(.User)
    }
    
    func exit() {
        
        events.onNext(.Exit)
    }
    
    init() {

        title.accept("แบบทดสอบความรู้")
        title2.accept("ภาคีวิศวกร")
        text.accept("แบบทดสอบเตรียมความพร้อม กว")
        selectTopic.accept("เลือกวิชา")
        colorGrad.accept([ .white, .white])
    }
    
    func changeNum(num: Int) {
        choiceNum.accept(num)
    }
}
