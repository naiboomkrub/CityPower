//
//  Operation.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


final class Operations: Foundation.Operation {
    
    private var _isExecuting = Atomic(false)
    private var _isFinished = Atomic(false)
    private var isFinishCalled = Atomic(false)

    override var isExecuting: Bool {
        get {
            _isExecuting.value
        }
        set {
            guard _isExecuting.value != newValue else {
                fatalError("Invalid state, operation is already (not) executing")
            }
            willChangeValue(forKey: "isExecuting")
            _isExecuting.value = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isFinished: Bool {
        get {
            _isFinished.value
        }
        set {
            guard !_isFinished.value else {
                fatalError("Invalid state, operation is already finished")
            }
            willChangeValue(forKey: "isFinished")
            _isFinished.value = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    typealias Starter = (_ finish: @escaping () -> Void) -> Void
    private let starter: Starter

    deinit {    }

    init(starter: @escaping Starter) {
        self.starter = starter
    }

    override func start() {
        guard !isCancelled else {
            isFinished = true
            return
        }
        isExecuting = true
        starter { [weak self] in
            self?._finish()
        }
    }

    private func _finish() {
        
        if isFinishCalled.swap(to: true, ifEqual: false) {
            isExecuting = false
            isFinished = true
        }
    }
}

extension OperationQueue {

    func add(_ closure: @escaping () -> Void) -> BlockOperation {
        let operation = BlockOperation(block: closure)
        addOperation(operation)
        return operation
    }

    func add(_ starter: @escaping Operations.Starter) -> Operations {
        let operation = Operations(starter: starter)
        addOperation(operation)
        return operation
    }
}
