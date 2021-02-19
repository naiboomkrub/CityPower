//
//  DataManager.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit

class DataManager {
    
    static let fileManager = FileManager.default
    var quizes = [Quiz]()
    
    func getQuizzes(_ categoryIn: String,_ numberOfChoice: Int) -> [Quiz] {
            
        if let path = Bundle.main.path(forResource: "quiz", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let jsonCategory = jsonResult["category"] as? [String], let jsonQuiz = jsonResult["quizes"] as? [[Dictionary<String, AnyObject>]] {
                    
                    for i in 0..<jsonCategory.count {
                        
                        if categoryIn.contains(jsonCategory[i]) {
                            
                            let shuffleQuiz = jsonQuiz[i].shuffled()
                            
                            for j in 0..<numberOfChoice{
                                quizes.append(Quiz(category: jsonCategory[i], quiz: shuffleQuiz[j])!)
                            }
                        }
                    }
                  }
              } catch { print("Data Error")  }
            
            return quizes
        }
        return []
    }
    
    func getQuizzes(_ categoryIn: String) -> [Quiz] {
            
        if let path = Bundle.main.path(forResource: "test", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject>, let jsonCategory = jsonResult["category"] as? [String], let jsonQuiz = jsonResult["quizes"] as? [[Dictionary<String, AnyObject>]] {
                    
                    for i in 0..<jsonCategory.count {
                        
                        if categoryIn.contains(jsonCategory[i]) {
                            
                            let shuffleQuiz = jsonQuiz[i].shuffled()
                            
                            for j in 0..<shuffleQuiz.count{
                                quizes.append(Quiz(category: jsonCategory[i], quiz: shuffleQuiz[j])!)
                            }
                        }
                    }
                  }
            } catch { print("Data Error")  }
            
            return quizes
        }
        return []
    }
}

extension MutableCollection {

    mutating func shuffle() {
        if count < 2 { return }

        for i in 0 ..< count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i)))
            if j != 0 {
                let current = index(startIndex, offsetBy: i)
                let swapped = index(current, offsetBy: j)
                swapAt(current, swapped)
            }
        }
    }

    func shufflled() -> Self {
        var results = self
        results.shuffle()
        return results
    }
}
