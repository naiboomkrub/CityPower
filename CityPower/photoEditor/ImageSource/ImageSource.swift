//
//  ImageSource.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit


public func dispatch_to_main_queue(block: @escaping () -> ()) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}


public protocol InitializableWithCGImage {

    init(cgImage: CGImage)
}


extension UIImage: InitializableWithCGImage { }

public protocol ImageSource: class {
    
    @discardableResult
    func requestImage<T: InitializableWithCGImage>(options: ImageRequestOptions,
        resultHandler: @escaping (ImageRequestResult<T>) -> ()) -> ImageRequestId
    
    func cancelRequest(_: ImageRequestId)

    func imageSize(completion: @escaping (CGSize?) -> ())
    
    func fullResolutionImageData(completion: @escaping (Data?) -> ())

    func isEqualTo(_ other: ImageSource) -> Bool
}

public func ==(lhs: ImageSource?, rhs: ImageSource?) -> Bool {
    if let lhs = lhs, let rhs = rhs {
        return lhs.isEqualTo(rhs)
    } else if let _ = lhs {
        return false
    } else if let _ = rhs {
        return false
    } else {
        return true
    }
}

public func !=(lhs: ImageSource?, rhs: ImageSource?) -> Bool {
    return !(lhs == rhs)
}


public struct ImageRequestId: Hashable, Equatable {
    
    internal let intValue: Int

    internal init(intValue: Int) {
        self.intValue = intValue
    }
    
    public init<T: Hashable>(hashable: T) {
        self.init(intValue: hashable.hashValue)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(intValue)
    }
    
    public static func ==(id1: ImageRequestId, id2: ImageRequestId) -> Bool {
        return id1.intValue == id2.intValue
    }
}


extension Int32 {
    func toImageRequestId() -> ImageRequestId {
        return ImageRequestId(intValue: Int(self))
    }
}

extension Int {
    func toImageRequestId() -> ImageRequestId {
        return ImageRequestId(intValue: self)
    }
}


public struct ImageRequestOptions {
    
    public var size: ImageSizeOption = .fullResolution
    public var deliveryMode: ImageDeliveryMode = .best
    public let needsMetadata: Bool
    
    public var onDownloadStart: ((ImageRequestId) -> ())?
    public var onDownloadFinish: ((ImageRequestId) -> ())?
    
    public init() {
        needsMetadata = false
    }
    
    public init(size: ImageSizeOption, deliveryMode: ImageDeliveryMode, needsMetadata: Bool = false) {
        self.size = size
        self.deliveryMode = deliveryMode
        self.needsMetadata = needsMetadata
    }
}

public enum ImageSizeOption: Equatable {
    
    case fitSize(CGSize)
    case fillSize(CGSize)
    case fullResolution
    
    public static func ==(sizeOption1: ImageSizeOption, sizeOption2: ImageSizeOption) -> Bool {
        switch (sizeOption1, sizeOption1) {
        case (.fitSize(let size1), .fitSize(let size2)):
            return size1 == size2
        case (.fillSize(let size1), .fillSize(let size2)):
            return size1 == size2
        case (.fullResolution, .fullResolution):
            return true
        default:
            return false
        }
    }
}


public enum ImageDeliveryMode {
    case progressive
    case best
}


public struct ImageMetadata {
    
    public let metadata: [String: Any]
    
    public init() {
        metadata = [:]
    }
    
    public init(_ metadata: [String: Any]?) {
        self.metadata = ImageMetadata.filteredAsJSONSerializable(metadata ?? [:])
    }
    
    public init(_ metadata: [NSObject: AnyObject]?) {
        self.metadata = ImageMetadata.convertObjcMetadata(metadata)
    }
    
    private static func convertObjcMetadata(_ objcMetadata: [NSObject: AnyObject]?) -> [String: Any] {
        guard let objcMetadata = objcMetadata else { return [:] }
        
        var result = [String: Any]()
        for (key, value) in objcMetadata {
            guard let key = key as? String else { continue }
            
            if let nested = value as? [NSObject: AnyObject] {
                result[key] = ImageMetadata.convertObjcMetadata(nested) as Any
            } else if JSONSerialization.isValidJSONObject([value]) {
                result[key] = value as Any
            }
        }
        return result
    }
    
    private static func filteredAsJSONSerializable(_ metadata: [String: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in metadata {
            if let nested = value as? [String: Any] {
                result[key] = ImageMetadata.filteredAsJSONSerializable(nested) as Any
            } else if JSONSerialization.isValidJSONObject([value]) {
                result[key] = value as Any
            }
        }
        return result
    }
}


public struct ImageRequestResult<T> {
    
    public let image: T?
    public let degraded: Bool
    public let requestId: ImageRequestId
    public let metadata: ImageMetadata
    
    public init(image: T?, degraded: Bool, requestId: ImageRequestId, metadata: ImageMetadata = ImageMetadata()) {
        self.image = image
        self.degraded = degraded
        self.requestId = requestId
        self.metadata = metadata
    }
}


struct SharedQueues {
    
    static let imageProcessingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 3
        
        return queue
    }()
}


public final class UIImageSourceView: UIView {
    
    private let imageView = UIImageView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var contentMode: UIView.ContentMode {
        get { return imageView.contentMode }
        set { imageView.contentMode = newValue }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
        
        updateImage()
    }
    
    public var imageSource: ImageSource? {
        didSet {
            setNeedsLayout()
        }
    }
    
    private func updateImage() {
        
        let sizeInPixels = CGSize(
            width: imageView.frame.width * contentScaleFactor,
            height: imageView.frame.height * contentScaleFactor
        )
        
        imageView.setImage(fromSource: imageSource, size: sizeInPixels)
    }
}


open class UIImageSourceCollectionViewCell: UICollectionViewCell {
    
    public var imageSource: ImageSource? {
        didSet {
            setNeedsLayout()
        }
    }
    
    public let imageView = UIImageView()
    public var imageViewInsets = UIEdgeInsets.zero
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        contentView.addSubview(imageView)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageFrame = contentView.bounds.inset(by: imageViewInsets)
        
        imageView.bounds = CGRect(origin: .zero, size: imageFrame.size)
        imageView.center = CGPoint(x: imageFrame.midX, y: imageFrame.midY)
        
        updateImage()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.setImage(fromSource: nil)
    }
    
    open func adjustImageRequestOptions(_ options: inout ImageRequestOptions) {}
    open func didRequestImage(requestId: ImageRequestId) {}
    open func imageRequestResultReceived(_ result: ImageRequestResult<UIImage>) {}
    
    
    private func updateImage() {

        var didCallRequestImage = false
        var delayedResult: ImageRequestResult<UIImage>?
        
        let requestId = imageView.setImage(
            fromSource: imageSource,
            placeholderDeferred: true,
            adjustOptions: { [weak self] options in
                self?.adjustImageRequestOptions(&options)
            },
            resultHandler: { [weak self] result in
                if didCallRequestImage {
                    self?.imageRequestResultReceived(result)
                } else {
                    delayedResult = result
                }
            }
        )
        
        if let requestId = requestId {
            
            didRequestImage(requestId: requestId)
            didCallRequestImage = true
            
            if let delayedResult = delayedResult {
                imageRequestResultReceived(delayedResult)
            }
        }
    }
}


protocol ImageRequestIdentifiable {
    var id: ImageRequestId { get }
}

class ThreadSafeIntGenerator {
    
    private var nextValue = 1
    private let queue = DispatchQueue(label: "com.CityPower.ThreadSafeIntGenerator.queue")
    
    func nextInt() -> Int {
        var value: Int = 0
        queue.sync {
            value = self.nextValue
            self.nextValue += 1
        }
        return value
    }
}

public final class CGImageWrapper: InitializableWithCGImage {
    
    public let image: CGImage
    
    public init(cgImage image: CGImage) {
        self.image = image
    }
}


