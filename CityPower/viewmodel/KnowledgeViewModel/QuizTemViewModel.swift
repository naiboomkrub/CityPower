//
//  QuizTemViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 15/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import CardParts
import RxDataSources


struct SelectStruct {
    var title: String
    var description: String
}

struct SectionOfSelectStruct {
    var header: String
    var items: [Item]
}

extension SectionOfSelectStruct: SectionModelType {

    typealias Item = SelectStruct

    init(original: SectionOfSelectStruct, items: [Item]) {
        self = original
        self.items = items
    }
}


class QuizTemViewModel {
    
    enum Event {
         case StartNormal
       }
    
    let events = PublishSubject<Event>()
    let quizTitle = BehaviorRelay(value: "")
    
    let quizSelected = BehaviorRelay(value: "General")
    
    typealias ReactiveSection = BehaviorRelay<[SectionOfSelectStruct]>
    var data = ReactiveSection(value: [])
    
    init(quizSelected: String) { quizTitle.accept(quizSelected) }
    
    func choseTopic() {

        events.onNext(.StartNormal)
      }
    
    func setTopic() {
        
        let allCategory: [SelectStruct] = [SelectStruct(title: "General", description: "General"),
                                           SelectStruct(title: "Installation", description: "Installation"),
                                           SelectStruct(title: "Test", description: "Test"),
                                           SelectStruct(title: "KorWor", description: "KorWor")]
        

        data.accept([SectionOfSelectStruct(header: "Lesson", items: allCategory)])

    }
    
}
