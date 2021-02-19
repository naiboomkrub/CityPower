//
//  KnowledgeMenuViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxSwift

class KnowledgeMenuViewModel {
    
    enum Event {
        case StartQuiz
        case StartLesson
    }
    let events = PublishSubject<Event>()
    
    func startQuiz() {
        events.onNext(.StartQuiz)
      }
    
    func startLesson() {
        events.onNext(.StartLesson)
      }
}
