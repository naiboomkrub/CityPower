//
//  SessionViewModel.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 27/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


enum ViewStackAction {
    case push(viewModel: Any)
    case set(viewModel: Any)
    case end
}

enum CheckAction {
    case check
    case swap
    case next
    case start
}
    
class SessionViewModel {
    
    enum Event {
         case Finish
       }
    
    let events = PublishSubject<Event>()
    
    let textOnly = BehaviorRelay(value: false)
    let enableButton = BehaviorRelay(value: false)
    let enableNext = BehaviorRelay(value: false)
    let category = BehaviorRelay(value: "")
    let imageTimer = BehaviorRelay(value: UIImage())
    let timePro = BehaviorRelay(value: "")
    let progressAttribute = BehaviorRelay(value: NSAttributedString())
    let timeNumber = BehaviorRelay(value: Int())
    let checkCorrect = BehaviorRelay(value: UIImage())
    let colorGrad = BehaviorRelay(value: [UIColor()])
    
    init(textOnly: Bool) {
        self.textOnly.accept(textOnly)
        colorGrad.accept([.white, .white])
        category.accept(GameSession.shared.getCurrentQuiz().mQuestion.mCategory)
        imageTimer.accept(UIImage(named:"timer-blue0")!)
    }
    
    var quizViewModel: QuizViewModel {
        if(_quizViewModel == nil) {
            _quizViewModel = createQuizViewModel()
        }
        return _quizViewModel!
    }
    
    var _quizViewModel: QuizViewModel?
    
    lazy private(set) var checkActions: BehaviorSubject<CheckAction> = BehaviorSubject(value: .start)
    lazy private(set) var viewStackActions: BehaviorSubject<ViewStackAction> = BehaviorSubject(value: .set(viewModel: self.quizViewModel))
       
    private let disposeBag = DisposeBag()
    
    func createQuizViewModel() -> QuizViewModel {
        
        let quizViewModel = QuizViewModel(textOnly: self.textOnly.value)
        
        quizViewModel.progress
            .subscribe(onNext: { [weak self] progress in
                self?.progressAttribute.accept(progress)
                self?.enableButton.accept(false)
                self?.checkActions.onNext(.start)

            }).disposed(by: disposeBag)
        
        quizViewModel.timerNumber
            .subscribe(onNext: { [weak self] number in
                
                self?.timePro.accept("\(number)")
                self?.timeNumber.accept(number)
                
                if number == 0 {
                    self?.enableButton.accept(true)
                    self?.checkActions.onNext(.swap)
                    
                } else if number < 30 {
                    self?.imageTimer.accept(UIImage(named:"timer-red0")!)
                } else {
                    self?.imageTimer.accept(UIImage(named:"timer-blue0")!)
                }
            }).disposed(by: disposeBag)
        
        quizViewModel.choicePick
            .subscribe(onNext: { [weak self] choice in
                if choice != -1 {
                    self?.enableNext.accept(true)
                    self?.checkActions.onNext(.check)
                }
                else {
                    self?.enableNext.accept(false)
                }
            }).disposed(by: disposeBag)
        
        quizViewModel.choicePick.subscribe(onNext: { [weak self] choice in
            if choice != -1 {
                self?.checkActions.onNext(.check) }
            }).disposed(by: disposeBag)
                
      return quizViewModel
    }
    
    func checkQuiz() {
        
        self.quizViewModel.onCheckClick()
        self.checkActions.onNext(.swap)
        if quizViewModel.correct {
            if let image = UIImage(named: "quiz-right0") {
                self.checkCorrect.accept(image)  }
        }
        else {
            if let image = UIImage(named: "quiz-wrong0") {
                self.checkCorrect.accept(image) }
        }
    }
    
    func nextQuiz() {
        
        if GameSession.shared.nextQuiz(){
            self.checkActions.onNext(.next)
            _quizViewModel = nil
            self.viewStackActions.onNext(.push(viewModel: self.quizViewModel))
        }
        else {
            self.viewStackActions.onNext(.end)
             events.onNext(.Finish)
        }
    }
}
