//
//  Deboucable.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


protocol Debouncable {
    func debounce(_ closure: @escaping () -> ())
    func cancel()
}

final class Debouncer: Debouncable {
    private var lastFireTime = DispatchTime(uptimeNanoseconds: 0)
    private let queue: DispatchQueue
    private let delay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(_ closure: @escaping () -> ()) {
        lastFireTime = DispatchTime.now()
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            if let strongSelf = self {
                let now = DispatchTime.now()
                let when = strongSelf.lastFireTime + strongSelf.delay
                if now >= when {
                    closure()
                }
            }
        }
    }
    
    func cancel() {
        debounce {}
    }
}
