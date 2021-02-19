//
//  DataCache.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CommonCrypto

public protocol DataCaching {

    func cachedData(for key: String) -> Data?

    func storeData(_ data: Data, for key: String)

    func removeData(for key: String)
}

public final class DataCache: DataCaching {

    public typealias Key = String
    public var countLimit: Int = 1000
    public var sizeLimit: Int = 1024 * 1024 * 100
    var trimRatio = 0.7
    public let path: URL
    public var sweepInterval: TimeInterval = 30
    private var initialSweepDelay: TimeInterval = 10

    private let lock = NSLock()
    private var staging = Staging()
    private var isFlushNeeded = false
    private var isFlushScheduled = false
    var flushInterval: DispatchTimeInterval = .seconds(2)

    public let queue = DispatchQueue(label: "com.CityPower.DataCache.WriteQueue", target: .global(qos: .utility))

    public typealias FilenameGenerator = (_ key: String) -> String?
    private let filenameGenerator: FilenameGenerator

    public convenience init(name: String, filenameGenerator: @escaping (String) -> String? = DataCache.filename(for:)) throws {
        guard let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        try self.init(path: root.appendingPathComponent(name, isDirectory: true), filenameGenerator: filenameGenerator)
    }

    public init(path: URL, filenameGenerator: @escaping (String) -> String? = DataCache.filename(for:)) throws {
        self.path = path
        self.filenameGenerator = filenameGenerator
        try self.didInit()
    }

    deinit { }

    public static func filename(for key: String) -> String? {
        return key.sha1
    }

    private func didInit() throws {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        queue.asyncAfter(deadline: .now() + initialSweepDelay) { [weak self] in
            self?.performAndScheduleSweep()
        }
    }

    public func cachedData(for key: Key) -> Data? {
        lock.lock()
        if let change = staging.change(for: key) {
            lock.unlock()
            switch change {
            case let .add(data):
                return data
            case .remove:
                return nil
            }
        }
        lock.unlock()

        guard let url = url(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    public func storeData(_ data: Data, for key: Key) {
        stage { staging.add(data: data, for: key) }
    }
    
    public func removeData(for key: Key) {
        stage { staging.removeData(for: key) }
    }

    public func removeAll() {
        stage { staging.removeAll() }
    }

    private func stage(_ change: () -> Void) {
        lock.lock()
        change()
        setNeedsFlushChanges()
        lock.unlock()
    }

    public subscript(key: Key) -> Data? {
        get {
            cachedData(for: key)
        }
        set {
            if let data = newValue {
                storeData(data, for: key)
            } else {
                removeData(for: key)
            }
        }
    }

    public func filename(for key: Key) -> String? {
        filenameGenerator(key)
    }

    public func url(for key: Key) -> URL? {
        guard let filename = self.filename(for: key) else {
            return nil
        }
        return self.path.appendingPathComponent(filename, isDirectory: false)
    }

    public func flush() {
        queue.sync(execute: flushChangesIfNeeded)
    }

    public func flush(for key: Key) {
        queue.sync {
            guard let change = lock.sync({ staging.changes[key] }) else { return }
            perform(change)
            lock.sync { staging.flushed(change) }
        }
    }

    private func setNeedsFlushChanges() {
        guard !isFlushNeeded else { return }
        isFlushNeeded = true
        scheduleNextFlush()
    }

    private func scheduleNextFlush() {
        guard !isFlushScheduled else { return }
        isFlushScheduled = true
        queue.asyncAfter(deadline: .now() + flushInterval, execute: flushChangesIfNeeded)
    }

    private func flushChangesIfNeeded() {
        
        let staging: Staging
        lock.lock()
        guard isFlushNeeded else { return lock.unlock() }
        staging = self.staging
        isFlushNeeded = false
        lock.unlock()

        performChanges(for: staging)

        lock.lock()
        self.staging.flushed(staging)
        isFlushScheduled = false
        if isFlushNeeded {
            scheduleNextFlush()
        }
        lock.unlock()
    }

    private func performChanges(for staging: Staging) {
        autoreleasepool {
            if let change = staging.changeRemoveAll {
                perform(change)
            }
            for change in staging.changes.values {
                perform(change)
            }
        }
    }

    private func perform(_ change: Staging.ChangeRemoveAll) {
        try? FileManager.default.removeItem(at: self.path)
        try? FileManager.default.createDirectory(at: self.path, withIntermediateDirectories: true, attributes: nil)
    }

    private func perform(_ change: Staging.Change) {
        guard let url = url(for: change.key) else {
            return
        }
        switch change.type {
        case let .add(data):
            do {
                try data.write(to: url)
            } catch let error as NSError {
                guard error.code == CocoaError.fileNoSuchFile.rawValue && error.domain == CocoaError.errorDomain else { return }
                try? FileManager.default.createDirectory(at: self.path, withIntermediateDirectories: true, attributes: nil)
                try? data.write(to: url)
            }
        case .remove:
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func performAndScheduleSweep() {
        performSweep()
        queue.asyncAfter(deadline: .now() + sweepInterval) { [weak self] in
            self?.performAndScheduleSweep()
        }
    }

    public func sweep() {
        queue.sync(execute: performSweep)
    }

    private func performSweep() {
        var items = contents(keys: [.contentAccessDateKey, .totalFileAllocatedSizeKey])
        guard !items.isEmpty else {
            return
        }
        var size = items.reduce(0) { $0 + ($1.meta.totalFileAllocatedSize ?? 0) }
        var count = items.count
        let sizeLimit = Int(Double(self.sizeLimit) * trimRatio)
        let countLimit = Int(Double(self.countLimit) * trimRatio)

        guard size > sizeLimit || count > countLimit else { return }

        let past = Date.distantPast
        items.sort {
            ($0.meta.contentAccessDate ?? past) > ($1.meta.contentAccessDate ?? past)
        }

        while (size > sizeLimit || count > countLimit), let item = items.popLast() {
            size -= (item.meta.totalFileAllocatedSize ?? 0)
            count -= 1
            try? FileManager.default.removeItem(at: item.url)
        }
    }

    struct Entry {
        let url: URL
        let meta: URLResourceValues
    }

    func contents(keys: [URLResourceKey] = []) -> [Entry] {
        guard let urls = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: keys, options: .skipsHiddenFiles) else { return [] }
        let keys = Set(keys)
        return urls.compactMap {
            guard let meta = try? $0.resourceValues(forKeys: keys) else { return nil }
            return Entry(url: $0, meta: meta)
        }
    }

    public var totalCount: Int { contents().count }
    public var totalSize: Int {
        contents(keys: [.fileSizeKey]).reduce(0) {
            $0 + ($1.meta.fileSize ?? 0)
        }
    }

    public var totalAllocatedSize: Int {
        contents(keys: [.totalFileAllocatedSizeKey]).reduce(0) {
            $0 + ($1.meta.totalFileAllocatedSize ?? 0)
        }
    }
}


private struct Staging {
    private(set) var changes = [String: Change]()
    private(set) var changeRemoveAll: ChangeRemoveAll?

    struct ChangeRemoveAll {
        let id: Int
    }

    struct Change {
        let key: String
        let id: Int
        let type: ChangeType
    }

    enum ChangeType {
        case add(Data)
        case remove
    }

    private var nextChangeId = 0

    func change(for key: String) -> ChangeType? {
        if let change = changes[key] {
            return change.type
        }
        if changeRemoveAll != nil {
            return .remove
        }
        return nil
    }

    mutating func add(data: Data, for key: String) {
        nextChangeId += 1
        changes[key] = Change(key: key, id: nextChangeId, type: .add(data))
    }

    mutating func removeData(for key: String) {
        nextChangeId += 1
        changes[key] = Change(key: key, id: nextChangeId, type: .remove)
    }

    mutating func removeAll() {
        nextChangeId += 1
        changeRemoveAll = ChangeRemoveAll(id: nextChangeId)
        changes.removeAll()
    }

    mutating func flushed(_ staging: Staging) {
        for change in staging.changes.values {
            flushed(change)
        }
        if let change = staging.changeRemoveAll {
            flushed(change)
        }
    }

    mutating func flushed(_ change: Change) {
        if let index = changes.index(forKey: change.key),
            changes[index].value.id == change.id {
            changes.remove(at: index)
        }
    }

    mutating func flushed(_ change: ChangeRemoveAll) {
        if changeRemoveAll?.id == change.id {
            changeRemoveAll = nil
        }
    }
}


extension String {

    var sha1: String? {
        guard let input = self.data(using: .utf8) else {
            return nil
        }

        let hash = input.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1(bytes.baseAddress, CC_LONG(input.count), &hash)
            return hash
        }

        return hash.map({ String(format: "%02x", $0) }).joined()
    }
}


extension NSLock {
    func sync<T>(_ closure: () -> T) -> T {
        lock()
        defer { unlock() }
        return closure()
    }
}
