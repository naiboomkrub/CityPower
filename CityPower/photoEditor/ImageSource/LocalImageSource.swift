//
//  LocalImageSource.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import ImageIO
import MobileCoreServices
import CoreLocation


public final class LocalImageSource: ImageSource {
    
    public let url: URL
    public var path: String { url.path }
    
    public init(path: String, previewImage: CGImage? = nil) {
        self.url = URL(fileURLWithPath: path)
        self.previewImage = previewImage
    }
    
    public init(url: URL, previewImage: CGImage? = nil) {
        assert(url.isFileURL, "File URL expected. Use `RemoteImageSource` for remote URLs.")
        
        self.url = url
        self.previewImage = previewImage
    }
        
    @discardableResult
    public func requestImage<T : InitializableWithCGImage>(options: ImageRequestOptions,
        resultHandler: @escaping (ImageRequestResult<T>) -> ())
        -> ImageRequestId {
        
        let requestId = LocalImageSource.requestIdsGenerator.nextInt().toImageRequestId()
        
        if let previewImage = previewImage, options.deliveryMode == .progressive {
            dispatch_to_main_queue {
                resultHandler(ImageRequestResult(image: T(cgImage: previewImage), degraded: true, requestId: requestId))
            }
        }
        
        let operation = LocalImageRequestOperation(
            id: requestId,
            path: path,
            options: options,
            resultHandler: resultHandler
        )
        
        SharedQueues.imageProcessingQueue.addOperation(operation)
        
        return requestId
    }
    
    public func cancelRequest(_ id: ImageRequestId) {
        for operation in SharedQueues.imageProcessingQueue.operations {
            if let identifiableOperation = operation as? ImageRequestIdentifiable, identifiableOperation.id == id {
                operation.cancel()
            }
        }
    }
    
    public func imageSize(completion: @escaping (CGSize?) -> ()) {
        if let fullSize = fullSize {
            dispatch_to_main_queue { completion(fullSize) }
        } else {
            SharedQueues.imageProcessingQueue.addOperation { [weak self, url] in
                
                let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions)
                let options = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) } as Dictionary?
                let width = options?[kCGImagePropertyPixelWidth] as? Int
                let height = options?[kCGImagePropertyPixelHeight] as? Int
                let orientation = options?[kCGImagePropertyOrientation] as? Int
                
                var size: CGSize? = nil
                
                if let width = width, let height = height {
                    
                    let exifOrientation = orientation.flatMap { ExifOrientation(rawValue: $0) }
                    let dimensionsSwapped = exifOrientation.flatMap { $0.dimensionsSwapped } ?? false
                    
                    size = CGSize(
                        width: dimensionsSwapped ? height : width,
                        height: dimensionsSwapped ? width : height
                    )
                }
                
                DispatchQueue.main.async {
                    self?.fullSize = size
                    completion(size)
                }
            }
        }
    }
    
    public func fullResolutionImageData(completion: @escaping (Data?) -> ()) {
        SharedQueues.imageProcessingQueue.addOperation { [url] in
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    public func isEqualTo(_ other: ImageSource) -> Bool {
        return (other as? LocalImageSource).flatMap { $0.path == path } ?? false
    }

    
    private static let requestIdsGenerator = ThreadSafeIntGenerator()
    
    private let previewImage: CGImage?
    private var fullSize: CGSize?
}


final class LocalImageRequestOperation<T: InitializableWithCGImage>: Operation, ImageRequestIdentifiable {
    
    let id: ImageRequestId
    
    private let path: String
    private let options: ImageRequestOptions
    private let callbackQueue: DispatchQueue
    private let resultHandler: (ImageRequestResult<T>) -> ()
    

    init(
        id: ImageRequestId,
        path: String,
        options: ImageRequestOptions,
        callbackQueue: DispatchQueue = .main,
        resultHandler: @escaping (ImageRequestResult<T>) -> ())
    {
        self.id = id
        self.path = path
        self.options = options
        self.callbackQueue = callbackQueue
        self.resultHandler = resultHandler
    }
    
    override func main() {
        switch options.size {
        case .fullResolution:
            getFullResolutionImage()
        case .fillSize(let size):
            getImage(resizedTo: size)
        case .fitSize(let size):
            getImage(resizedTo: size)
        }
    }
    
    // MARK: - Private
    
    private func getFullResolutionImage() {
        
        guard !isCancelled else { return }
        let url = NSURL(fileURLWithPath: path)
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let source = CGImageSourceCreateWithURL(url, sourceOptions)
        
        let cfProperties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) }
        let imageMetadata = cfProperties as [NSObject: AnyObject]? ?? [:]
        
        let orientation = imageMetadata[kCGImagePropertyOrientation] as? Int
        
        let imageCreationOptions = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        
        guard !isCancelled else { return }
        var cgImage = source.flatMap { CGImageSourceCreateImageAtIndex($0, 0, imageCreationOptions) }
        
        if let exifOrientation = orientation.flatMap({ ExifOrientation(rawValue: $0) }) {
            guard !isCancelled else { return }
            cgImage = cgImage?.imageFixedForOrientation(exifOrientation)
        }
        
        guard !isCancelled else { return }
        callbackQueue.async { [resultHandler, id] in
            resultHandler(ImageRequestResult(
                image: cgImage.flatMap { T(cgImage: $0) },
                degraded: false,
                requestId: id,
                metadata: ImageMetadata(self.options.needsMetadata ? imageMetadata : nil)
            ))
        }
    }
    
    private func getImage(resizedTo size: CGSize) {
        guard !isCancelled else { return }
        
        let url = NSURL(fileURLWithPath: path)
        
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        let source = CGImageSourceCreateWithURL(url, sourceOptions)
        var imageMetadata = [NSObject: AnyObject]()
        
        if self.options.needsMetadata {
            let cfProperties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) }
            imageMetadata = cfProperties as [NSObject: AnyObject]? ?? [:]
        }
        
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        guard !isCancelled else { return }
        let cgImage = source.flatMap { CGImageSourceCreateThumbnailAtIndex($0, 0, options as CFDictionary) }
        
        guard !isCancelled else { return }
        callbackQueue.async { [resultHandler, id] in
            resultHandler(ImageRequestResult(
                image: cgImage.flatMap { T(cgImage: $0) },
                degraded: false,
                requestId: id,
                metadata: ImageMetadata(imageMetadata)
            ))
        }
    }
}
