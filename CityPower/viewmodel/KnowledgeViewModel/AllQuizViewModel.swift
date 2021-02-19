//
//  AllQuizViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources

struct QuizStruct {
    var title: String
    var description: String
    var number: String
}

struct SectionOfQuizStruct {
    var header: String
    var items: [Item]
}

extension SectionOfQuizStruct: SectionModelType {

    typealias Item = QuizStruct

    init(original: SectionOfQuizStruct, items: [Item]) {
        self = original
        self.items = items
    }
}


class AllQuizViewModel {
    
    enum Event {
        case KorWor
        case Quiz
     }
    
    let events = PublishSubject<Event>()
    let quizSelected = BehaviorRelay(value: "")
    
    typealias ReactiveSection = BehaviorRelay<[SectionOfQuizStruct]>
    var data = ReactiveSection(value: [])
    
    func startQuiz() {
          
        events.onNext(.KorWor)
    }
    
    func startNormalQuiz(selectQuiz: String) {
          
        quizSelected.accept(selectQuiz)
        events.onNext(.Quiz)
    }
    
    func setTopic() {
        
        let allCategory: [QuizStruct] = [QuizStruct(title: "General", description: "General Knowledge",                                 number: "0"),
                                         QuizStruct(title: "Installation Test", description: "Technical Knowledge", number: "10"),
                                         QuizStruct(title: "Engineering Test", description: "Basic Knowledge", number: "20"),
                                         QuizStruct(title: "KorWor", description: "Preparation For KorWor", number: "0")]
        

        data.accept([SectionOfQuizStruct(header: "Lesson", items: allCategory)])

    }
    
}
