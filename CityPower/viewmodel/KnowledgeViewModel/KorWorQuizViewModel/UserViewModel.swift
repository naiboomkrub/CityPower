//
//  UserViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 16/9/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class UserViewModel {
    
    let username = BehaviorRelay(value: "")
    let pointAll = BehaviorRelay(value: NSAttributedString())
    let correctAll = BehaviorRelay(value: "")
    let incorrectAll = BehaviorRelay(value: "")
    let picGrade = BehaviorRelay(value: UIImage())
    
    let attrs1 = [NSAttributedString.Key.font : UIFont(name: "SukhumvitSet-Bold", size: CGFloat(30))!, NSAttributedString.Key.foregroundColor : UIColor.blueCity]
    
    let attrs2 = [NSAttributedString.Key.font : UIFont(name: "Baskerville-Bold", size: CGFloat(50))!, NSAttributedString.Key.foregroundColor : UIColor.blueCity]
    
    init() {
        username.accept(UserDefaultsManager.username)
    }
    
    func setUsername(nameIn: String) {
        username.accept(nameIn)
        UserDefaultsManager.username = nameIn
    }
    
    func refreshData() {
        
        let attributedString1 = NSMutableAttributedString(string:"Score ", attributes:attrs1)

        let attributedString2 = NSMutableAttributedString(string:"\(UserDefaultsManager.score)", attributes:attrs2)
        
        attributedString1.append(attributedString2)
        pointAll.accept(attributedString1)
        correctAll.accept("\(UserDefaultsManager.correctAnswers)")
        incorrectAll.accept("\(UserDefaultsManager.incorrectAnswers)")
    }
    
    func resetData() {
        UserDefaultsManager.score = 0
        UserDefaultsManager.correctAnswers = 0
        UserDefaultsManager.incorrectAnswers = 0
        UserDefaultsManager.username = "Username"
    }
    
    func getResult() {
        
        UserDefaultsManager.score += GameSession.shared.mTotalCorrect
        
        let totalCorrect : Int = UserDefaultsManager.correctAnswers
        let totalQuiz : Int = UserDefaultsManager.incorrectAnswers
        var percentage : Int = 0

        if totalQuiz != 0 {
            percentage = (totalCorrect/totalQuiz) * 10 }
        
        if  percentage < 3 {
            picGrade.accept(UIImage(named: "score-d0")!)
        } else if percentage < 6{
            picGrade.accept(UIImage(named: "score-c0")!)
        } else if percentage < 8{
            picGrade.accept(UIImage(named: "score-b0")!)
        } else {
            picGrade.accept(UIImage(named: "score-a0")!)
        }
    }
}
