//
//  DataEncoding.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import UIKit
import ImageIO


public protocol ImageEncoding {
    
    func encode(_ image: PlatformImage) -> Data?

    func encode(_ container: ImageContainer, context: ImageEncodingContext) -> Data?
}

public extension ImageEncoding {
    func encode(_ container: ImageContainer, context: ImageEncodingContext) -> Data? {
        self.encode(container.image)
    }
}

public typealias ImageEncoder = ImageEncoders.Default

public struct ImageEncodingContext {
    public let request: DataRequest
    public let image: PlatformImage
    public let urlResponse: URLResponse?
}

public enum ImageEncoders { }

public extension ImageEncoders {

    struct Default: ImageEncoding {
        
        public var compressionQuality: Float

        public init(compressionQuality: Float = 0.8) {
            self.compressionQuality = compressionQuality
        }

        public func encode(_ image: PlatformImage) -> Data? {
            guard let cgImage = image.cgImage else {
                return nil
            }
            
            let type: ImageType
            if cgImage.isOpaque {
                type = .jpeg
            } else {
                type = .png
            }
            
            let encoder = ImageEncoders.ImageIO(type: type, compressionRatio: compressionQuality)
            return encoder.encode(image)
        }
    }
}

public extension ImageEncoders {
    
    struct ImageIO: ImageEncoding {
        public let type: ImageType
        public let compressionRatio: Float

        public init(type: ImageType, compressionRatio: Float = 0.8) {
            self.type = type
            self.compressionRatio = compressionRatio
        }

        private static let lock = NSLock()
        private static var availability = [ImageType: Bool]()

        public static func isSupported(type: ImageType) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if let isAvailable = availability[type] {
                return isAvailable
            }
            let isAvailable = CGImageDestinationCreateWithData(
                NSMutableData() as CFMutableData, type.rawValue as CFString, 1, nil
            ) != nil
            availability[type] = isAvailable
            
            return isAvailable
        }

        public func encode(_ image: PlatformImage) -> Data? {
            let data = NSMutableData()
            let options: NSDictionary = [
                kCGImageDestinationLossyCompressionQuality: compressionRatio
            ]
            guard let source = image.cgImage,
                let destination = CGImageDestinationCreateWithData(
                    data as CFMutableData, type.rawValue as CFString, 1, nil
                ) else {
                    return nil
            }
            CGImageDestinationAddImage(destination, source, options)
            CGImageDestinationFinalize(destination)
            return data as Data
        }
    }
}
