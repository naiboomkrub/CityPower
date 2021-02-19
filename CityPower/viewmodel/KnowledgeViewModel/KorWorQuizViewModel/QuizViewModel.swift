//
//  QuizViewModel.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 26/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import CardParts

class QuizViewModel {
    
    var timer = Timer()
    var counter = 60
    var correct : Bool = true
    var checked: Bool = false
    
    let state = BehaviorRelay(value: false)
    let timerNumber = BehaviorRelay(value: 60)
    let progress = BehaviorRelay(value: NSMutableAttributedString())
    let image1 = BehaviorRelay(value: "")
    let title = BehaviorRelay(value: "")
    let title1 = BehaviorRelay(value: "")
    let title2 = BehaviorRelay(value: "")
    let title3 = BehaviorRelay(value: "")
    let title4 = BehaviorRelay(value: "")
    let title5 = BehaviorRelay(value: "")
    let choicePick = BehaviorRelay(value: -1)
    
    let color1 = BehaviorRelay(value: UIColor.white)
    let color2 = BehaviorRelay(value: UIColor.white)
    let color3 = BehaviorRelay(value: UIColor.white)
    let color4 = BehaviorRelay(value: UIColor.white)
    let color5 = BehaviorRelay(value: UIColor.white)
    
    let enableButton = BehaviorRelay(value: true)
    
    let attrs1 = [NSAttributedString.Key.font : UIFont(name: "Baskerville-Bold", size: CGFloat(70))!, NSAttributedString.Key.foregroundColor : UIColor.blueCity]

    let attrs2 = [NSAttributedString.Key.font : UIFont(name: "Baskerville-Bold", size: CGFloat(40))!, NSAttributedString.Key.foregroundColor : UIColor.blueCity]
    
    init(textOnly: Bool) {
                
        if textOnly {
            state.accept(false)
        } else {
            state.accept(true)
        }
        
        let attributedString1 = NSMutableAttributedString(string:"\((GameSession.shared.mCurrentQuizIndex) + 1)", attributes:attrs1)

        let attributedString2 = NSMutableAttributedString(string:" / \(GameSession.shared.getTotalQuiz())", attributes:attrs2)
        
        attributedString1.append(attributedString2)
        
        let currentQuiz = GameSession.shared.getCurrentQuiz()
        image1.accept(currentQuiz.mQuestion.mContent)
        title.accept(currentQuiz.mQuestion.mContent)
        title1.accept(currentQuiz.mChoices[0].mContent)
        title2.accept(currentQuiz.mChoices[1].mContent)
        title3.accept(currentQuiz.mChoices[2].mContent)
        title4.accept(currentQuiz.mChoices[3].mContent)
        title5.accept(currentQuiz.mChoices[4].mContent)
        
        progress.accept(attributedString1)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
        
    @objc func timerAction() {
        if counter > 0 {
            counter -= 1
            timerNumber.accept(counter)
        }
        else {

            for n in 0...4 {
                if GameSession.shared.getCurrentQuiz().mChoices[n].mIsTheAnswer {
                    setColor(num: n, color: UIColor.correct)
                }
            }
            timer.invalidate()
            choicePick.accept(-1)
            enableButton.accept(false)
            counter = 0
            
            if !checked {
                GameSession.shared.mBoolean.append(false)
                UserDefaultsManager.incorrectAnswers += 1
                checked = true
            }
        }
    }
    
    func onChoiceClick(_ index: Int) {

            choicePick.accept(index)
    }
    
    func setColor(num: Int, color: UIColor) {
        
        switch num {
        case 0:
            color1.accept(color)
        case 1:
            color2.accept(color)
        case 2:
            color3.accept(color)
        case 3:
            color4.accept(color)
        case 4:
            color5.accept(color)
        default:
            color1.accept(color)
        }
    }
    
    func onCheckClick() {
        
        if choicePick.value != -1 && !checked {
            
            enableButton.accept(false)
            timerNumber.accept(0)
            timer.invalidate()
            
            if GameSession.shared.getCurrentQuiz().mChoices[choicePick.value].mIsTheAnswer {
                GameSession.shared.addPoint()
                GameSession.shared.mBoolean.append(true)
                setColor(num: choicePick.value, color: UIColor.correct)
                UserDefaultsManager.correctAnswers += 1
                correct = true
            }
        
            else {
                setColor(num: choicePick.value, color: UIColor.wrong)
                GameSession.shared.mBoolean.append(false)
                UserDefaultsManager.incorrectAnswers += 1
            
                for n in 0...4 {
                    if GameSession.shared.getCurrentQuiz().mChoices[n].mIsTheAnswer {
                        setColor(num: n, color: UIColor.correct)
                    }
                }
                correct = false
            }
        
            choicePick.accept(-1)
            checked = true
        }
    }
}

