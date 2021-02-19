//
//  RateLimiter.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


final class RateLimiter {
    
    private let bucket: TokenBucket
    private let queue: DispatchQueue
    private var pending = LinkedList<Work>()
    private var isExecutingPendingTasks = false

    typealias Work = () -> Bool

    init(queue: DispatchQueue, rate: Int = 80, burst: Int = 25) {
        self.queue = queue
        self.bucket = TokenBucket(rate: Double(rate), burst: Double(burst))
    }

    deinit { }

    func execute( _ work: @escaping Work) {
        if !pending.isEmpty || !bucket.execute(work) {
            pending.append(work)
            setNeedsExecutePendingTasks()
        }
    }

    private func setNeedsExecutePendingTasks() {
        guard !isExecutingPendingTasks else { return }
        isExecutingPendingTasks = true
        let delay = Int(2.1 * (1000 / bucket.rate))
        let bounds = min(100, max(15, delay))
        queue.asyncAfter(deadline: .now() + .milliseconds(bounds), execute: executePendingTasks)
    }

    private func executePendingTasks() {
        while let node = pending.first, bucket.execute(node.value) {
            pending.remove(node)
        }
        isExecutingPendingTasks = false
        if !pending.isEmpty {
            setNeedsExecutePendingTasks()
        }
    }
}

private final class TokenBucket {
    let rate: Double
    private let burst: Double
    private var bucket: Double
    private var timestamp: TimeInterval
    
    init(rate: Double, burst: Double) {
        self.rate = rate
        self.burst = burst
        self.bucket = burst
        self.timestamp = CFAbsoluteTimeGetCurrent()
    }

    func execute(_ work: () -> Bool) -> Bool {
        refill()
        guard bucket >= 1.0 else {
            return false
        }
        if work() {
            bucket -= 1.0
        }
        return true
    }

    private func refill() {
        let now = CFAbsoluteTimeGetCurrent()
        bucket += rate * max(0, now - timestamp)
        timestamp = now
        if bucket > burst {
            bucket = burst
        }
    }
}


final class LinkedList<Element> {
    
    private(set) var first: Node?
    private(set) var last: Node?

    deinit { removeAll() }

    init() {    }

    var isEmpty: Bool {
        last == nil
    }

    @discardableResult
    func append(_ element: Element) -> Node {
        let node = Node(value: element)
        append(node)
        return node
    }

    /// Adds a node to the end of the list.
    func append(_ node: Node) {
        if let last = last {
            last.next = node
            node.previous = last
            self.last = node
        } else {
            last = node
            first = node
        }
    }

    func remove(_ node: Node) {
        node.next?.previous = node.previous
        node.previous?.next = node.next
        if node === last {
            last = node.previous
        }
        if node === first {
            first = node.next
        }
        node.next = nil
        node.previous = nil
    }

    func removeAll() {
        
        var node = first
        while let next = node?.next {
            node?.next = nil
            next.previous = nil
            node = next
        }
        last = nil
        first = nil
    }

    final class Node {
        let value: Element
        fileprivate var next: Node?
        fileprivate var previous: Node?

        init(value: Element) {
            self.value = value
        }
    }
}
