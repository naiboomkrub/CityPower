//
//  LessonViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources

struct LessonStruct {
    var title: String
    var description: String
}

struct SectionOfLessonStruct {
    var header: String
    var items: [Item]
}

extension SectionOfLessonStruct: SectionModelType {

    typealias Item = LessonStruct

    init(original: SectionOfLessonStruct, items: [Item]) {
        self = original
        self.items = items
    }
}


class LessonViewModel {
    
    enum Event {
       case ChoseTopic
     }
    
    let events = PublishSubject<Event>()
    let contentHeader = BehaviorRelay(value: "")
    
    typealias ReactiveSection = BehaviorRelay<[SectionOfLessonStruct]>
    var data = ReactiveSection(value: [])
    
    init() { }
        
    func setTopic() {
        
        let allCategory: [LessonStruct] = [LessonStruct(title: "General", description: "General"),
                                           LessonStruct(title: "Mechanic", description: "Mechanical"),
                                           LessonStruct(title: "Electrical", description: "Electrical"),
                                           LessonStruct(title: "Sanitary", description: "Sanitary")]
        

        data.accept([SectionOfLessonStruct(header: "Lesson", items: allCategory)])

    }
    
    func choseTopic(_ header: String) {
        contentHeader.accept(header)
        events.onNext(.ChoseTopic)
      }
}
