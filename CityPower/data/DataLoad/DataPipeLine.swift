//
//  DataPipeLine.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


public class DataPipeLine {

    public let configuration: Configuration
    public var observer: ImagePipelineObserving?

    private var tasks = [DataTask: TaskSubscription]()

    private let decompressedImageTasks: TaskPool<DataRequest.LoadKeyForProcessedImage, ImageResponse, Error>
    private let processedImageTasks: TaskPool<DataRequest.LoadKeyForProcessedImage, ImageResponse, Error>
    private let originalImageTasks: TaskPool<DataRequest.LoadKeyForOriginalImage, ImageResponse, Error>
    private let originalImageDataTasks: TaskPool<DataRequest.LoadKeyForOriginalImage, (Data, URLResponse?), Error>

    private var nextTaskId = Atomic<Int>(0)

    private let queue = DispatchQueue(label: "com.CityPower.DataPipeline", target: .global(qos: .userInitiated))
    private var isInvalidated = false

    let rateLimiter: RateLimiter?
    let id = UUID()

    public static var shared = DataPipeLine()

    deinit { ResumableDataStorage.shared.unregister(self) }

    public init(configuration: Configuration = Configuration()) {

        self.configuration = configuration
        self.rateLimiter = configuration.isRateLimiterEnabled ? RateLimiter(queue: queue) : nil

        let isDeduplicationEnabled = configuration.isDeduplicationEnabled
        self.decompressedImageTasks = TaskPool(isDeduplicationEnabled)
        self.processedImageTasks = TaskPool(isDeduplicationEnabled)
        self.originalImageTasks = TaskPool(isDeduplicationEnabled)
        self.originalImageDataTasks = TaskPool(isDeduplicationEnabled)

        ResumableDataStorage.shared.register(self)
    }

    public convenience init(_ configure: (inout DataPipeLine.Configuration) -> Void) {
        var configuration = DataPipeLine.Configuration()
        configure(&configuration)
        self.init(configuration: configuration)
    }

    func invalidate() {
        queue.async {
            guard !self.isInvalidated else { return }
            self.isInvalidated = true
            self.tasks.keys.forEach(self.cancel)
        }
    }

    @discardableResult
    public func loadImage(with request: ImageRequestConvertible,
                          queue: DispatchQueue? = nil,
                          completion: @escaping DataTask.Completion) -> DataTask {
        loadImage(with: request, queue: queue, progress: nil, completion: completion)
    }
    
    @discardableResult
    public func loadImage(with request: ImageRequestConvertible,
                          queue callbackQueue: DispatchQueue? = nil,
                          progress progressHandler: DataTask.ProgressHandler? = nil,
                          completion: DataTask.Completion? = nil) -> DataTask {
        loadImage(with: request.asImageRequest(), isMainThreadConfined: false, queue: callbackQueue, progress: progressHandler, completion: completion)
    }

    func loadImage(with request: DataRequest,
                   isMainThreadConfined: Bool,
                   queue callbackQueue: DispatchQueue?,
                   progress progressHandler: DataTask.ProgressHandler?,
                   completion: DataTask.Completion?) -> DataTask {
        let request = inheritOptions(request)
        let task = DataTask(taskId: nextTaskId.increment(), request: request, isMainThreadConfined: isMainThreadConfined, isDataTask: false)
        task.pipeline = self
        self.queue.async {
            self.startImageTask(task, callbackQueue: callbackQueue, progress: progressHandler, completion: completion)
        }
        return task
    }

    @discardableResult
    public func loadData(with request: ImageRequestConvertible,
                         queue callbackQueue: DispatchQueue? = nil,
                         completion: @escaping (Result<(data: Data, response: URLResponse?), DataPipeLine.Error>) -> Void) -> DataTask {
        loadData(with: request, queue: callbackQueue, progress: nil, completion: completion)
    }

    @discardableResult
    public func loadData(with request: ImageRequestConvertible,
                         queue callbackQueue: DispatchQueue? = nil,
                         progress: ((_ completed: Int64, _ total: Int64) -> Void)? = nil,
                         completion: @escaping (Result<(data: Data, response: URLResponse?), DataPipeLine.Error>) -> Void) -> DataTask {
        let request = request.asImageRequest()
        let task = DataTask(taskId: nextTaskId.increment(), request: request, isDataTask: true)
        task.pipeline = self
        self.queue.async {
            self.startDataTask(task, callbackQueue: callbackQueue, progress: progress, completion: completion)
        }
        return task
    }

    func imageTaskCancelCalled(_ task: DataTask) {
        queue.async {
            self.cancel(task)
        }
    }

    private func cancel(_ task: DataTask) {
        guard let subscription = self.tasks.removeValue(forKey: task) else { return }
        if !task.isDataTask {
            self.send(.cancelled, task)
        }
        subscription.unsubscribe()
    }

    func imageTaskUpdatePriorityCalled(_ task: DataTask, priority: DataRequest.Priority) {
        queue.async {
            task._priority = priority
            guard let subscription = self.tasks[task] else { return }
            if !task.isDataTask {
                self.send(.priorityUpdated(priority: priority), task)
            }
            subscription.setPriority(priority.taskPriority)
        }
    }
}


public extension DataPipeLine {
    
    func cachedImage(for url: URL) -> ImageContainer? {
        cachedImage(for: DataRequest(url: url))
    }

    func cachedImage(for request: DataRequest) -> ImageContainer? {
        guard request.options.memoryCacheOptions.isReadAllowed && request.cachePolicy != .reloadIgnoringCachedData else { return nil }

        let request = inheritOptions(request)
        return configuration.imageCache?[request]
    }

    internal func storeResponse(_ image: ImageContainer, for request: DataRequest) {
        guard request.options.memoryCacheOptions.isWriteAllowed,
            !image.isPreview || configuration.isStoringPreviewsInMemoryCache else { return }
        configuration.imageCache?[request] = image
    }

    func cacheKey(for request: DataRequest, item: DataCacheItem) -> String {
        switch item {
        case .originalImageData: return request.makeCacheKeyForOriginalImageData()
        case .finalImage: return request.makeCacheKeyForFinalImageData()
        }
    }

    func removeCachedImage(for request: DataRequest) {
        let request = inheritOptions(request)

        configuration.imageCache?[request] = nil

        if let dataCache = configuration.dataCache {
            dataCache.removeData(for: request.makeCacheKeyForOriginalImageData())
            dataCache.removeData(for: request.makeCacheKeyForFinalImageData())
        }

        configuration.dataLoader.removeData(for: request.urlRequest)
    }
}

private extension DataPipeLine {
    
    func startImageTask(_ task: DataTask,
                        callbackQueue: DispatchQueue?,
                        progress progressHandler: DataTask.ProgressHandler?,
                        completion: DataTask.Completion?) {
     
        guard !isInvalidated else { return }

        self.send(.started, task)

        tasks[task] = makeTaskLoadData(for: task.request)
            .subscribe(priority: task._priority.taskPriority) { [weak self, weak task] event in
                guard let self = self, let task = task else { return }

                self.send(ImageTaskEvent(event), task)

                if event.isCompleted {
                    self.tasks[task] = nil
                }

                (callbackQueue ?? self.configuration.callbackQueue).async {
                    guard !task.isCancelled else { return }

                    switch event {
                    case let .value(response, isCompleted):
                        if isCompleted {
                            completion?(.success(response))
                        } else {
                            progressHandler?(response, task.completedUnitCount, task.totalUnitCount)
                        }
                    case let .progress(progress):
                        task.setProgress(progress)
                        progressHandler?(nil, progress.completed, progress.total)
                    case let .error(error):
                        completion?(.failure(error))
                    }
                }
        }
    }

    func startDataTask(_ task: DataTask,
                       callbackQueue: DispatchQueue?,
                       progress progressHandler: ((_ completed: Int64, _ total: Int64) -> Void)?,
                       completion: @escaping (Result<(data: Data, response: URLResponse?), DataPipeLine.Error>) -> Void) {
        guard !isInvalidated else { return }

        tasks[task] = makeTaskLoadImageData(for: task.request)
            .subscribe(priority: task._priority.taskPriority) { [weak self, weak task] event in
                guard let self = self, let task = task else { return }

                if event.isCompleted {
                    self.tasks[task] = nil
                }

                (callbackQueue ?? self.configuration.callbackQueue).async {
                    guard !task.isCancelled else { return }

                    switch event {
                    case let .value(response, isCompleted):
                        if isCompleted {
                            completion(.success(response))
                        }
                    case let .progress(progress):
                        task.setProgress(progress)
                        progressHandler?(progress.completed, progress.total)
                    case let .error(error):
                        completion(.failure(error))
                    }
                }
        }
    }
}


extension DataPipeLine {

    func makeTaskLoadData(for request: DataRequest) -> Generate<ImageResponse, DataPipeLine.Error>.Publisher {
        decompressedImageTasks.publisherForKey(request.makeLoadKeyForFinalImage()) {
            GenerateLoadData(self, request, queue)
        }
    }

    func makeTaskProcessImage(for request: DataRequest) -> Generate<ImageResponse, DataPipeLine.Error>.Publisher {
        request.processors.isEmpty ?
            makeTaskDecodeImage(for: request) :
            processedImageTasks.publisherForKey(request.makeLoadKeyForFinalImage()) {
                GenerateProcess(self, request, queue)
            }
    }
    
    func makeTaskDecodeImage(for request: DataRequest) -> Generate<ImageResponse, DataPipeLine.Error>.Publisher {
        originalImageTasks.publisherForKey(request.makeLoadKeyForOriginalImage()) {
            GenerateDecodeImage(self, request, queue)
        }
    }
    
    func makeTaskLoadImageData(for request: DataRequest) -> Generate<(Data, URLResponse?), DataPipeLine.Error>.Publisher {
        originalImageDataTasks.publisherForKey(request.makeLoadKeyForOriginalImage()) {
            GenerateLoadImageData(self, request, queue)
        }
    }
}

private extension DataPipeLine {

    func inheritOptions(_ request: DataRequest) -> DataRequest {

        guard request.processors.isEmpty, !configuration.processors.isEmpty else { return request }

        var request = request
        request.processors = configuration.processors
        return request
    }

    func send(_ event: ImageTaskEvent, _ task: DataTask) {
        observer?.pipeline(self, imageTask: task, didReceiveEvent: event)
    }
}


public extension DataPipeLine {

    enum Error: Swift.Error, CustomDebugStringConvertible {

        case dataLoadingFailed(Swift.Error)
        case decodingFailed
        case processingFailed

        public var debugDescription: String {
            switch self {
            case let .dataLoadingFailed(error): return "Failed to load image data: \(error)"
            case .decodingFailed: return "Failed to create an image from the image data"
            case .processingFailed: return "Failed to process the image"
            }
        }
    }
}


