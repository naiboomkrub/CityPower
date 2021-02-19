//
//  Choice.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation

struct Choices {
    var mId: Int = -1
    var mContent: String = ""
    var mIsTheAnswer: Bool = false
    
    init(mIsTheAnswer: Bool, mContent: String, mId: Int) {
        self.mId = mId;
        self.mContent = mContent
        self.mIsTheAnswer = mIsTheAnswer
    
    }
    
    init?(choiceObj: Dictionary<String, Bool>){
        for (content, answers) in choiceObj{
            mContent = content
            mIsTheAnswer = answers
            mId = -1
        }
    }
}

extension Choices: Equatable {
static func == (lhs: Choices, rhs: Choices) -> Bool {
    return
        lhs.mContent == rhs.mContent &&
        lhs.mIsTheAnswer == rhs.mIsTheAnswer
    }
}
