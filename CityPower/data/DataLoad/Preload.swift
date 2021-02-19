//
//  Preload.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


public final class Preload {

    private let pipeline: DataPipeLine
    private let queue = DispatchQueue(label: "com.CityPower.data.Preload", target: .global(qos: .userInitiated))
    private let preheatQueue = OperationQueue()
    private var tasks = [AnyHashable: Task]()
    private let destination: Destination

    public enum Destination {
        case memoryCache
        case diskCache
    }

    public init(pipeline: DataPipeLine = DataPipeLine.shared,
                destination: Destination = .memoryCache,
                maxConcurrentRequestCount: Int = 2) {
        self.pipeline = pipeline
        self.destination = destination
        self.preheatQueue.maxConcurrentOperationCount = maxConcurrentRequestCount

    }

    deinit {
        let tasks = self.tasks.values
        queue.async {
            for task in tasks {
                task.cancel()
            }
        }
    }

    public func startPreheating(with urls: [URL]) {
        startPreheating(with: _requests(for: urls))
    }

    public func startPreheating(with requests: [DataRequest]) {
        queue.async {
            for request in requests {
                self._startPreheating(with: request)
            }
        }
    }

    private func _startPreheating(with request: DataRequest) {
        let key = request.makeLoadKeyForFinalImage()

        guard tasks[key] == nil else { return }
        guard pipeline.configuration.imageCache?[request] == nil else { return }

        let task = Task(request: request, key: key)

        let operation = Operations(starter: { [weak self, weak task] finish in
            guard let self = self, let task = task else {
                return finish()
            }
            self.queue.async {
                self.loadImage(with: request, task: task, finish: finish)
            }
        })
        preheatQueue.addOperation(operation)
        tasks[key] = task
    }

    private func loadImage(with request: DataRequest, task: Task, finish: @escaping () -> Void) {
        guard !task.isCancelled else {
            return finish()
        }

        let imageTask: DataTask
        switch destination {
        case .diskCache:
            imageTask = pipeline.loadData(with: request) { [weak self] _ in
                self?._remove(task)
                finish()
            }
        case .memoryCache:
            imageTask = pipeline.loadImage(with: request, completion: { [weak self] _ in
                self?._remove(task)
                finish()
            })
        }
        task.onCancelled = {
            imageTask.cancel()
            finish()
        }
    }

    private func _remove(_ task: Task) {
        queue.async {
            guard self.tasks[task.key] === task else { return }
            self.tasks[task.key] = nil
        }
    }

    public func stopPreheating(with urls: [URL]) {
        stopPreheating(with: _requests(for: urls))
    }

    public func stopPreheating(with requests: [DataRequest]) {
        queue.async {
            for request in requests {
                self._stopPreheating(with: request)
            }
        }
    }

    private func _stopPreheating(with request: DataRequest) {
        if let task = tasks[request.makeLoadKeyForFinalImage()] {
            tasks[task.key] = nil
            task.cancel()
        }
    }

    public func stopPreheating() {
        queue.async {
            self.tasks.values.forEach { $0.cancel() }
            self.tasks.removeAll()
        }
    }

    private func _requests(for urls: [URL]) -> [DataRequest] {
        return urls.map {
            var request = DataRequest(url: $0)
            request.priority = .low
            return request
        }
    }

    private final class Task {
        let key: AnyHashable
        let request: DataRequest
        var isCancelled = false
        var onCancelled: (() -> Void)?
        weak var operation: Operations?

        init(request: DataRequest, key: AnyHashable) {
            self.request = request
            self.key = key
        }

        func cancel() {
            guard !isCancelled else { return }
            isCancelled = true
            operation?.cancel()
            onCancelled?()
        }
    }
}
