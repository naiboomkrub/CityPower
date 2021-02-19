//
//  DataTask.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit.UIImage


public class DataTask: Hashable, CustomStringConvertible {
   
    public let taskId: Int
    let isDataTask: Bool
    weak var pipeline: DataPipeLine?
    public let request: DataRequest


    public var priority: DataRequest.Priority {
        didSet {
            pipeline?.imageTaskUpdatePriorityCalled(self, priority: priority)
        }
    }

    var _priority: DataRequest.Priority
    
    public internal(set) var completedUnitCount: Int64 = 0
    public internal(set) var totalUnitCount: Int64 = 0

    public var progress: Progress {
        if _progress == nil { _progress = Progress() }
        return _progress!
    }
    private(set) var _progress: Progress?

    var isCancelled: Bool {
        lock?.lock()
        defer { lock?.unlock() }
        return _isCancelled
    }
    
    private(set) var _isCancelled = false
    private let lock: NSLock?

    public typealias Completion = (_ result: Result<ImageResponse, DataPipeLine.Error>) -> Void

    public typealias ProgressHandler = (_ intermediateResponse: ImageResponse?, _ completedUnitCount: Int64, _ totalUnitCount: Int64) -> Void

    init(taskId: Int, request: DataRequest, isMainThreadConfined: Bool = false, isDataTask: Bool) {
        self.taskId = taskId
        self.request = request
        self._priority = request.priority
        self.priority = request.priority
        self.isDataTask = isDataTask
        lock = isMainThreadConfined ? nil : NSLock()
    }

    public func cancel() {
        if let lock = lock {
            lock.lock()
            defer { lock.unlock() }
            _cancel()
        } else {
            assert(Thread.isMainThread, "Must be cancelled only from the main thread")
            _cancel()
        }
    }

    private func _cancel() {
        if !_isCancelled {
            _isCancelled = true
            pipeline?.imageTaskCancelCalled(self)
        }
    }

    func setProgress(_ progress: TaskProgress) {
        completedUnitCount = progress.completed
        totalUnitCount = progress.total
        _progress?.completedUnitCount = progress.completed
        _progress?.totalUnitCount = progress.total
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    public static func == (lhs: DataTask, rhs: DataTask) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public var description: String {
        "DataTask(id: \(taskId), priority: \(priority), completedUnitCount: \(completedUnitCount), totalUnitCount: \(totalUnitCount), isCancelled: \(isCancelled))"
    }
}

public struct ImageContainer {

    public var image: PlatformImage
    public var type: ImageType?
    public var isPreview: Bool

    public var data: Data?
    public var userInfo: [AnyHashable: Any]

    public init(image: PlatformImage, type: ImageType? = nil, isPreview: Bool = false, data: Data? = nil, userInfo: [AnyHashable: Any] = [:]) {
        self.image = image
        self.type = type
        self.isPreview = isPreview
        self.data = data
        self.userInfo = userInfo
    }

    public func map(_ closure: (PlatformImage) -> PlatformImage?) -> ImageContainer? {
        guard let image = closure(self.image) else {
            return nil
        }
        return ImageContainer(image: image, type: type, isPreview: isPreview, data: data, userInfo: userInfo)
    }
}


public final class ImageResponse {

    public let container: ImageContainer
    
    public var image: PlatformImage { container.image }
    public let urlResponse: URLResponse?
    public var scanNumber: Int? {
        if let number = _scanNumber {
            return number
        }
        return container.userInfo["ImageDecoders.Default.scanNumberKey"] as? Int
    }
    
    private let _scanNumber: Int?

    @available(*, deprecated, message: "Please use `ImageResponse.init(container:urlResponse:)` instead.")
    public init(image: PlatformImage, urlResponse: URLResponse? = nil, scanNumber: Int? = nil) {
        self.container = ImageContainer(image: image)
        self.urlResponse = urlResponse
        self._scanNumber = scanNumber
    }

    public init(container: ImageContainer, urlResponse: URLResponse? = nil) {
        self.container = container
        self.urlResponse = urlResponse
        self._scanNumber = nil
    }

    func map(_ transformation: (ImageContainer) -> ImageContainer?) -> ImageResponse? {
        return autoreleasepool {
            guard let output = transformation(container) else {
                return nil
            }
            return ImageResponse(container: output, urlResponse: urlResponse)
        }
    }
}
