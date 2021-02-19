//
//  QuizResultViewModel.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 27/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources


struct DataCell {
    let index: String
    let color: Bool
}

struct SectionOfCustomStruct {
    var header: String
    var items: [Item]
}

extension SectionOfCustomStruct: SectionModelType {
    
    typealias Item = DataCell
    
    init(original: SectionOfCustomStruct, items: [Item]) {
        self = original
        self.items = items
    }
}

class QuizResultViewModel {
    
    enum Event {
       case Quit
     }
    
    typealias ReactiveSection = BehaviorRelay<[SectionOfCustomStruct]>
    var data = ReactiveSection(value: [])
    
    let events = PublishSubject<Event>()
    
    let listData: BehaviorRelay<[DataCell]> = BehaviorRelay(value: [])
    let title1 = BehaviorRelay(value: UIImage())
    let title2 = BehaviorRelay(value: "")
    let score = BehaviorRelay(value: "")
    let name = BehaviorRelay(value: "")
    
    init() {   
        
        data.accept([SectionOfCustomStruct(header: "", items: setData())])
        name.accept(UserDefaultsManager.username)
        listData.accept(setData())
        getResult()
    }
    
    private func getResult() {
        
        UserDefaultsManager.score += GameSession.shared.mTotalCorrect
        
        let totalCorrect : Int = GameSession.shared.mTotalCorrect
        let totalQuiz : Int = GameSession.shared.getTotalQuiz()
        let percentage : Int = (totalCorrect/totalQuiz) * 10
        if  percentage < 3 {
            title1.accept(UIImage(named: "score-d0")!)
        } else if percentage < 6{
            title1.accept(UIImage(named: "score-c0")!)
        } else if percentage < 8{
            title1.accept(UIImage(named: "score-b0")!)
        } else {
            title1.accept(UIImage(named: "score-a0")!)
        }
        
        title2.accept("/ \(totalQuiz)")
        score.accept("\(totalCorrect)")
    }
    
    func quit() {
          
          events.onNext(.Quit)
      }
    
    func setData() -> [DataCell]{
        
        var tempData: [DataCell] = []
        for (index, element) in GameSession.shared.mBoolean.enumerated() {
            if (index + 1) > GameSession.shared.getTotalQuiz() { break }
            tempData.append(DataCell(index: "\(index + 1)", color: element))
        }
        return tempData
    }
}
