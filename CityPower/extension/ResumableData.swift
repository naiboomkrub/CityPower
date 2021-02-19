//
//  ResumableData.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


struct ResumableData {

    let data: Data
    let validator: String
    init?(response: URLResponse, data: Data) {
       
        guard !data.isEmpty,
            let response = response as? HTTPURLResponse,
            data.count < response.expectedContentLength,
            response.statusCode == 200 || response.statusCode == 206,
            let acceptRanges = response.allHeaderFields["Accept-Ranges"] as? String,
            acceptRanges.lowercased() == "bytes",
            let validator = ResumableData._validator(from: response) else {
                return nil
        }

        self.data = data; self.validator = validator
    }

    private static func _validator(from response: HTTPURLResponse) -> String? {
        if let entityTag = response.allHeaderFields["ETag"] as? String {
            return entityTag
        }
        if let entityTag = response.allHeaderFields["Etag"] as? String {
            return entityTag
        }
        if let lastModified = response.allHeaderFields["Last-Modified"] as? String {
            return lastModified
        }
        return nil
    }

    func resume(request: inout URLRequest) {
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Range"] = "bytes=\(data.count)-"
        headers["If-Range"] = validator
        request.allHTTPHeaderFields = headers
    }

    static func isResumedResponse(_ response: URLResponse) -> Bool {
        (response as? HTTPURLResponse)?.statusCode == 206
    }
}


final class ResumableDataStorage {
    
    static let shared = ResumableDataStorage()

    private let lock = NSLock()
    private var registeredPipelines = Set<UUID>()

    private var cache: Cache<Key, ResumableData>?

    func register(_ pipeline: DataPipeLine) {
        lock.lock(); defer { lock.unlock() }

        if registeredPipelines.isEmpty {
            cache = Cache(costLimit: 32 * 1024 * 1024, countLimit: 100)
        }
        registeredPipelines.insert(pipeline.id)
    }

    func unregister(_ pipeline: DataPipeLine) {
        lock.lock(); defer { lock.unlock() }

        registeredPipelines.remove(pipeline.id)
        if registeredPipelines.isEmpty {
            cache = nil
        }
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        cache?.removeAll()
    }

    func removeResumableData(for request: DataRequest, pipeline: DataPipeLine) -> ResumableData? {
        lock.lock(); defer { lock.unlock() }

        guard let cache = cache,
              cache.totalCount > 0,
              let key = Key(request: request, pipeline: pipeline) else {
            return nil
        }
        return cache.removeValue(forKey: key)
    }

    func storeResumableData(_ data: ResumableData, for request: DataRequest, pipeline: DataPipeLine) {
        lock.lock(); defer { lock.unlock() }

        guard let key = Key(request: request, pipeline: pipeline) else { return }
        cache?.set(data, forKey: key, cost: data.data.count)
    }

    private struct Key: Hashable {
        let pipelineId: UUID
        let url: String

        init?(request: DataRequest, pipeline: DataPipeLine) {
            guard let url = request.urlString else {
                return nil
            }
            self.pipelineId = pipeline.id
            self.url = url
        }
    }
}
