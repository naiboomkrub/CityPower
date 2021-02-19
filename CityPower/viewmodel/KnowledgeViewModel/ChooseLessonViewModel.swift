//
//  ChooseLessonViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 9/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

struct SubTopicStruct {
    var title: String
    var description: String
}

struct SectionOfSubTopicStruct {
    var header: String
    var items: [Item]
}

extension SectionOfSubTopicStruct: SectionModelType {

    typealias Item = SubTopicStruct

    init(original: SectionOfSubTopicStruct, items: [Item]) {
        self = original
        self.items = items
    }
}

class ChooseLessonViewModel {
    
    enum Event {
       case StartLesson
     }
    
    let events = PublishSubject<Event>()
    let topicHeader = BehaviorRelay(value: "")
    
    typealias ReactiveSection = BehaviorRelay<[SectionOfSubTopicStruct]>
    var data = ReactiveSection(value: [])
    
    func setTopic() {
        
        let allCategory: [SubTopicStruct] = [SubTopicStruct(title: "General", description: "General"),
                                             SubTopicStruct(title: "Mechanic", description: "Mechanical"),
                                             SubTopicStruct(title: "Electrical", description: "Electrical"),
                                             SubTopicStruct(title: "Sanitary", description: "Sanitary")]
        

        data.accept([SectionOfSubTopicStruct(header: "", items: allCategory)])

    }
    
    func startLesson() {
          
        events.onNext(.StartLesson)
    }
    
}
