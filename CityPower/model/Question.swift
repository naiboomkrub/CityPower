//
//  Question.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation

struct Question {
    var mId: Int
    var mContent: String
    var mCategory: String
    
    init(mCategory: String, mContent: String, mId: Int) {
        self.mId = mId;
        self.mContent = mContent
        self.mCategory = mCategory
    }
}
    
extension Question: Equatable {
    static func == (lhs: Question, rhs: Question) -> Bool {
        return
            lhs.mContent == rhs.mContent &&
            lhs.mCategory == rhs.mCategory
    }
}

extension Question: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.mContent.hash)
        hasher.combine(self.mCategory.hash)
    }
}
