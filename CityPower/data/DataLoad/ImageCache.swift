//
//  ImageCache.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


public protocol ImageCaching: AnyObject {
    
    subscript(request: DataRequest) -> ImageContainer? { get set }
}

public final class ImageCache: ImageCaching {
    
    private let impl: Cache<DataRequest.CacheKey, ImageContainer>

    public var costLimit: Int {
        get { impl.costLimit }
        set { impl.costLimit = newValue }
    }

    public var countLimit: Int {
        get { impl.countLimit }
        set { impl.countLimit = newValue }
    }

    public var ttl: TimeInterval {
        get { impl.ttl }
        set { impl.ttl = newValue }
    }

    public var totalCost: Int {
        return impl.totalCost
    }

    public var totalCount: Int {
        return impl.totalCount
    }

    public static let shared = ImageCache()

    deinit {    }

    public init(costLimit: Int = ImageCache.defaultCostLimit(), countLimit: Int = Int.max) {
        impl = Cache(costLimit: costLimit, countLimit: countLimit)
    }

    public static func defaultCostLimit() -> Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let ratio = physicalMemory <= (536_870_912) ? 0.1 : 0.2
        let limit = physicalMemory / UInt64(1 / ratio)
        return limit > UInt64(Int.max) ? Int.max : Int(limit)
    }

    public subscript(request: DataRequest) -> ImageContainer? {
        get {
            let key = request.makeCacheKeyForFinalImage()
            return impl.value(forKey: key)
        }
        set {
            let key = request.makeCacheKeyForFinalImage()
            if let image = newValue {
                impl.set(image, forKey: key, cost: self.cost(for: image))
            } else {
                impl.removeValue(forKey: key)
            }
        }
    }

    public func removeAll() {
        impl.removeAll()
    }

    public func trim(toCost limit: Int) {
        impl.trim(toCost: limit)
    }

    public func trim(toCount limit: Int) {
        impl.trim(toCount: limit)
    }

    func cost(for container: ImageContainer) -> Int {
        let dataCost: Int
        
        dataCost = container.data?.count ?? 0

        guard let cgImage = container.image.cgImage else {
            return 1 + dataCost
        }
        return cgImage.bytesPerRow * cgImage.height + dataCost
    }
}

final class Cache<Key: Hashable, Value> {
    
    private var map = [Key: LinkedList<Entry>.Node]()
    private let list = LinkedList<Entry>()
    private let lock = NSLock()
    private let memoryPressure: DispatchSourceMemoryPressure

    var costLimit: Int {
        didSet { lock.sync(_trim) }
    }

    var countLimit: Int {
        didSet { lock.sync(_trim) }
    }

    private(set) var totalCost = 0
    var ttl: TimeInterval = 0

    var totalCount: Int {
        map.count
    }

    init(costLimit: Int, countLimit: Int) {
        self.costLimit = costLimit
        self.countLimit = countLimit
        self.memoryPressure = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        self.memoryPressure.setEventHandler { [weak self] in
            self?.removeAll()
        }
        self.memoryPressure.resume()

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(didEnterBackground),
                           name: UIApplication.didEnterBackgroundNotification,
                           object: nil)

    }

    deinit {
        memoryPressure.cancel()
    }

    func value(forKey key: Key) -> Value? {
        lock.lock(); defer { lock.unlock() }

        guard let node = map[key] else {
            return nil
        }

        guard !node.value.isExpired else {
            _remove(node: node)
            return nil
        }
        list.remove(node)
        list.append(node)

        return node.value.value
    }

    func set(_ value: Value, forKey key: Key, cost: Int = 0, ttl: TimeInterval? = nil) {
        lock.lock(); defer { lock.unlock() }

        let ttl = ttl ?? self.ttl
        let expiration = ttl == 0 ? nil : (Date() + ttl)
        let entry = Entry(value: value, key: key, cost: cost, expiration: expiration)
        _add(entry)
        _trim()
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        lock.lock(); defer { lock.unlock() }

        guard let node = map[key] else {
            return nil
        }
        _remove(node: node)
        return node.value.value
    }

    private func _add(_ element: Entry) {
        if let existingNode = map[element.key] {
            _remove(node: existingNode)
        }
        map[element.key] = list.append(element)
        totalCost += element.cost
    }

    private func _remove(node: LinkedList<Entry>.Node) {
        list.remove(node)
        map[node.value.key] = nil
        totalCost -= node.value.cost
    }

    @objc
    dynamic func removeAll() {
        lock.sync {
            map.removeAll()
            list.removeAll()
            totalCost = 0
        }
    }

    private func _trim() {
        _trim(toCost: costLimit)
        _trim(toCount: countLimit)
    }

    @objc
    private dynamic func didEnterBackground() {

        lock.sync {
            _trim(toCost: Int(Double(costLimit) * 0.1))
            _trim(toCount: Int(Double(countLimit) * 0.1))
        }
    }

    func trim(toCost limit: Int) {
        lock.sync { _trim(toCost: limit) }
    }

    private func _trim(toCost limit: Int) {
        _trim(while: { totalCost > limit })
    }

    func trim(toCount limit: Int) {
        lock.sync { _trim(toCount: limit) }
    }

    private func _trim(toCount limit: Int) {
        _trim(while: { totalCount > limit })
    }

    private func _trim(while condition: () -> Bool) {
        while condition(), let node = list.first {
            _remove(node: node)
        }
    }

    private struct Entry {
        let value: Value
        let key: Key
        let cost: Int
        let expiration: Date?
        var isExpired: Bool {
            guard let expiration = expiration else {
                return false
            }
            return expiration.timeIntervalSinceNow < 0
        }
    }
}
