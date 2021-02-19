//
//  DataPipeLineConfiguration.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation


extension DataPipeLine {
    
    public struct Configuration {

        public var imageCache: ImageCaching? {

            get {
                isCustomImageCacheProvided ? customImageCache : ImageCache.shared
            }
            set {
                customImageCache = newValue
                isCustomImageCacheProvided = true
            }
        }
        
        private var customImageCache: ImageCaching?
        private var isCustomImageCacheProvided = false

        public var dataLoader: DataLoading
        public var dataCache: DataCaching?

        public var makeImageDecoder: (ImageDecodingContext) -> ImageDecoding? = ImageDecoderRegistry.shared.decoder(for:)
        public var makeImageEncoder: (ImageEncodingContext) -> ImageEncoding = { _ in
            ImageEncoders.Default()
        }


        public var dataLoadingQueue = OperationQueue()
        public var dataCachingQueue = OperationQueue()
        public var imageDecodingQueue = OperationQueue()
        public var imageEncodingQueue = OperationQueue()
        public var imageProcessingQueue = OperationQueue()
        public var imageDecompressingQueue = OperationQueue()
        
        public var processors: [ImageProcessing] = []

        public var callbackQueue = DispatchQueue.main
        public var isDecompressionEnabled = true

        public var dataCacheOptions = DataCacheOptions()

        public struct DataCacheOptions {
            public var storedItems: Set<DataCacheItem> = [.originalImageData]
        }

        public var isDeduplicationEnabled = true
        public var isRateLimiterEnabled = true
        public var isProgressiveDecodingEnabled = false
        public var isStoringPreviewsInMemoryCache = false
        public var isResumableDataEnabled = true

        static var _isAnimatedImageDataEnabled = false

        public static var isSignpostLoggingEnabled = false

        public init(dataLoader: DataLoading = DataLoader()) {
            self.dataLoader = dataLoader

            self.dataLoadingQueue.maxConcurrentOperationCount = 6
            self.dataCachingQueue.maxConcurrentOperationCount = 2
            self.imageDecodingQueue.maxConcurrentOperationCount = 1
            self.imageEncodingQueue.maxConcurrentOperationCount = 1
            self.imageProcessingQueue.maxConcurrentOperationCount = 2
        }

        public init(dataLoader: DataLoading = DataLoader(), imageCache: ImageCaching?) {
            self.init(dataLoader: dataLoader)
            self.customImageCache = imageCache
            self.isCustomImageCacheProvided = true
        }
    }

    public enum DataCacheItem {
        case originalImageData
        case finalImage
    }
}

public enum ImageTaskEvent {
    case started
    case cancelled
    case priorityUpdated(priority: DataRequest.Priority)
    case intermediateResponseReceived(response: ImageResponse)
    case progressUpdated(completedUnitCount: Int64, totalUnitCount: Int64)
    case completed(result: Result<ImageResponse, DataPipeLine.Error>)
}

public protocol ImagePipelineObserving {
    func pipeline(_ pipeline: DataPipeLine, imageTask: DataTask, didReceiveEvent event: ImageTaskEvent)
}

extension ImageTaskEvent {
    init(_ event: Generate<ImageResponse, DataPipeLine.Error>.Event) {
        switch event {
        case let .error(error):
            self = .completed(result: .failure(error))
        case let .value(response, isCompleted):
            if isCompleted {
                self = .completed(result: .success(response))
            } else {
                self = .intermediateResponseReceived(response: response)
            }
        case let .progress(progress):
            self = .progressUpdated(completedUnitCount: progress.completed, totalUnitCount: progress.total)
        }
    }
}
