//
//  Quiz.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation

struct Quiz {
    
    var mQuestion: Question
    var mChoices: [Choices]
    var mChosen: Choices = Choices(mIsTheAnswer: false, mContent: "", mId: -1)
    
    init(mQuestion: Question, mChoices: [Choices], mChosen: Choices){
        self.mQuestion = mQuestion
        self.mChoices = mChoices
        self.mChosen = mChosen
    }
    
    init?(category: String, quiz: Dictionary<String, AnyObject>){
        self.mQuestion = Question(mCategory: category, mContent: quiz["question"] as! String, mId: -1)
        self.mChoices = [Choices]()
        let choices = quiz["choices"] as! [Dictionary<String, Bool>]
        for choice in choices {
            mChoices.append(Choices(choiceObj: choice)!)
        }
    }
}

extension Quiz: Equatable {
    static func == (lhs: Quiz, rhs: Quiz) -> Bool {
        return
            lhs.mQuestion == rhs.mQuestion
    }
}

