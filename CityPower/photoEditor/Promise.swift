//
//  Promise.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


struct Promise<T> {
    
    typealias Handler = (T) -> ()
    
    private var handlers = [Handler]()
    private var value: T?
    
    mutating func onFulfill(handler: @escaping Handler) {
        if let value = value {  
            handler(value)
        } else {
            handlers.append(handler)
        }
    }
    
    mutating func fulfill(_ value: T) {
        self.value = value
        
        if handlers.count > 0 {
            handlers.forEach { $0(value) }
            handlers.removeAll()
        }
    }
}
