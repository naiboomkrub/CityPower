//
//  Atomic.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


final class Atomic<T> {
    private var _value: T
    private let lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

    deinit { }

    var value: T {
        get {
            lock.lock()
            let value = _value
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            _value = newValue
            lock.unlock()
        }
    }
}

extension Atomic where T: Equatable {

    func swap(to newValue: T, ifEqual oldValue: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard _value == oldValue else { return false }
        _value = newValue
        return true
    }

    func map(_ transform: (T) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }

        _value = transform(_value)
        return _value
    }
}

extension Atomic where T == Int {
    
    @discardableResult func increment() -> Int {
        map { $0 + 1 }
    }

    @discardableResult func decrement() -> Int {
        map { $0 - 1 }
    }
}
