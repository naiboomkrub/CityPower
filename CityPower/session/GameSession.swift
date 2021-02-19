//
//  GameSession.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation

class GameSession {
    
    var mQuizes: [Quiz] = []
    var mCategory: [String] = []
    var mCurrentQuizIndex: Int
    var mChoiceNumber: Int
    var mTotalCorrect: Int
    var mGameController: [QuizViewController] = []
    var mBoolean: [Bool] = []
    static let shared = GameSession()
    
    private init() {
        mCurrentQuizIndex = 0
        mChoiceNumber = 0
        mTotalCorrect = 0
    }
    
    public func setCategory(newCategory: [String]) {
        mCategory.removeAll()
        mCategory.append(contentsOf: newCategory)
    }
    
    public func setNumber(choiceNumber: Int){
        mChoiceNumber = choiceNumber
    }
    
    public func resetSession() {
        mGameController.removeAll()
        mBoolean.removeAll()
        mQuizes.removeAll()
        mCurrentQuizIndex = 0
        mTotalCorrect = 0
    }
    
    public func setQuizzes(newQuiz: [Quiz]){
        mQuizes.append(contentsOf: newQuiz)
    }
    
    public func getCurrentQuiz() -> Quiz{
        return mQuizes[mCurrentQuizIndex]
    }
    
    public func hasMoreQuiz() -> Bool{
        return mCurrentQuizIndex < mQuizes.count - 1
    }
    
    public func nextQuiz() -> Bool{
        if hasMoreQuiz(){
            mCurrentQuizIndex += 1
            return true
        }
        return false
    }
    
    public func addPoint(){
        mTotalCorrect += 1
    }
    
    public func getTotalQuiz() -> Int{
        return mQuizes.count
    }
    
}
