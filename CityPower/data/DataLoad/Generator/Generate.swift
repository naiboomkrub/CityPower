//
//  Generate.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


class Generate<Value, Error>: TaskSubscriptionDelegate {

    private struct Subscription {
        let observer: (Event) -> Void
        var priority: TaskPriority
    }

    private var inlineSubscription: Subscription?
    private var subscriptions: [TaskSubscriptionKey: Subscription]?
    private var nextSubscriptionKey = 0

    private(set) var isDisposed = false
    private var isStarted = false

    var onDisposed: (() -> Void)?
    var onCancelled: (() -> Void)?

    private var priority: TaskPriority = .normal {
        didSet {
            guard oldValue != priority else { return }
            operation?.queuePriority = priority.queuePriority
            dependency?.setPriority(priority)
        }
    }

    var dependency: TaskSubscription? {
        didSet {
            dependency?.setPriority(priority)
        }
    }

    weak var operation: Foundation.Operation? {
        didSet {
            guard priority != .normal else { return }
            operation?.queuePriority = priority.queuePriority
        }
    }

    var publisher: Publisher { Publisher(task: self) }

    func start() {}

    private func subscribe(priority: TaskPriority = .normal, _ observer: @escaping (Event) -> Void) -> TaskSubscription? {
        guard !isDisposed else { return nil }

        let subscriptionKey = nextSubscriptionKey
        nextSubscriptionKey += 1
        let subscription = TaskSubscription(task: self, key: subscriptionKey)

        if subscriptionKey == 0 {
            inlineSubscription = Subscription(observer: observer, priority: priority)
        } else {
            if subscriptions == nil { subscriptions = [:] }
            subscriptions![subscriptionKey] = Subscription(observer: observer, priority: priority)
        }

        updatePriority(suggestedPriority: priority)

        if !isStarted {
            isStarted = true
            start()
        }

        guard !isDisposed else { return nil }

        return subscription
    }

    fileprivate func setPriority(_ priority: TaskPriority, for key: TaskSubscriptionKey) {
        guard !isDisposed else { return }

        if key == 0 {
            inlineSubscription?.priority = priority
        } else {
            subscriptions![key]?.priority = priority
        }
        updatePriority(suggestedPriority: priority)
    }

    fileprivate func unsubsribe(key: TaskSubscriptionKey) {
        if key == 0 {
            guard inlineSubscription != nil else { return }
            inlineSubscription = nil
        } else {
            guard subscriptions!.removeValue(forKey: key) != nil else { return }
        }

        guard !isDisposed else { return }

        if inlineSubscription == nil && subscriptions?.isEmpty ?? true {
            terminate(reason: .cancelled)
        } else {
            updatePriority(suggestedPriority: nil)
        }
    }

    func send(value: Value, isCompleted: Bool = false) {
        send(event: .value(value, isCompleted: isCompleted))
    }

    func send(error: Error) {
        send(event: .error(error))
    }

    func send(progress: TaskProgress) {
        send(event: .progress(progress))
    }

    private func send(event: Event) {
        guard !isDisposed else { return }

        switch event {
        case let .value(_, isCompleted):
            if isCompleted {
                terminate(reason: .finished)
            }
        case .progress:
            break
        case .error:
            terminate(reason: .finished)
        }

        inlineSubscription?.observer(event)
        if let subscriptions = subscriptions {
            for subscription in subscriptions.values {
                subscription.observer(event)
            }
        }
    }

    private enum TerminationReason {
        case finished, cancelled
    }

    private func terminate(reason: TerminationReason) {
        guard !isDisposed else { return }
        isDisposed = true

        if reason == .cancelled {
            operation?.cancel()
            dependency?.unsubscribe()
            onCancelled?()
        }
        onDisposed?()
    }

    private func updatePriority(suggestedPriority: TaskPriority?) {
        if let suggestedPriority = suggestedPriority, suggestedPriority >= priority {
            priority = suggestedPriority
            return
        }

        var newPriority = inlineSubscription?.priority

        if let subscriptions = subscriptions {
            for subscription in subscriptions.values {
                if newPriority == nil {
                    newPriority = subscription.priority
                } else if subscription.priority > newPriority! {
                    newPriority = subscription.priority
                }
            }
        }
        self.priority = newPriority ?? .normal
    }
}


extension Generate {
    struct Publisher {
        
        fileprivate let task: Generate

        func subscribe(priority: TaskPriority = .normal, _ observer: @escaping (Event) -> Void) -> TaskSubscription? {
            task.subscribe(priority: priority, observer)
        }

        func subscribe<NewValue>(_ task: Generate<NewValue, Error>, onValue: @escaping (Value, Bool) -> Void) -> TaskSubscription? {
            subscribe { [weak task] event in
                guard let task = task else { return }
                switch event {
                case let .value(value, isCompleted):
                    onValue(value, isCompleted)
                case let .progress(progress):
                    task.send(progress: progress)
                case let .error(error):
                    task.send(error: error)
                }
            }
        }
    }
}

struct TaskProgress: Hashable {
    let completed: Int64
    let total: Int64
}

enum TaskPriority: Int, Comparable {
    case veryLow = 0, low, normal, high, veryHigh

    var queuePriority: Operation.QueuePriority {
        switch self {
        case .veryLow: return .veryLow
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .veryHigh: return .veryHigh
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


extension Generate {
    
    enum Event {
        case value(Value, isCompleted: Bool)
        case progress(TaskProgress)
        case error(Error)

        var isCompleted: Bool {
            switch self {
            case let .value(_, isCompleted): return isCompleted
            case .progress: return false
            case .error: return true
            }
        }
    }
}

extension Generate.Event: Equatable where Value: Equatable, Error: Equatable {}


struct TaskSubscription {
    private let task: TaskSubscriptionDelegate
    private let key: TaskSubscriptionKey

    fileprivate init(task: TaskSubscriptionDelegate, key: TaskSubscriptionKey) {
        self.task = task
        self.key = key
    }

    func unsubscribe() {
        task.unsubsribe(key: key)
    }
    
    func setPriority(_ priority: TaskPriority) {
        task.setPriority(priority, for: key)
    }
}

private protocol TaskSubscriptionDelegate: AnyObject {
    func unsubsribe(key: TaskSubscriptionKey)
    func setPriority(_ priority: TaskPriority, for observer: TaskSubscriptionKey)
}

private typealias TaskSubscriptionKey = Int


final class TaskPool<Key: Hashable, Value, Error> {
    private let isDeduplicationEnabled: Bool
    private var map = [Key: Generate<Value, Error>]()

    init(_ isDeduplicationEnabled: Bool) {
        self.isDeduplicationEnabled = isDeduplicationEnabled
    }

    func publisherForKey(_ key: Key, _ make: () -> Generate<Value, Error>) -> Generate<Value, Error>.Publisher {
        guard isDeduplicationEnabled else {
            return make().publisher
        }
        if let task = map[key] {
            return task.publisher
        }
        let task = make()
        map[key] = task
        task.onDisposed = { [weak self] in
            self?.map[key] = nil
        }
        return task.publisher
    }
}
