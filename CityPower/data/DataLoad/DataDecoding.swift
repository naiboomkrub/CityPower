//
//  DataDecoding.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import UIKit
import PDFKit

public protocol ImageDecoding {

    func decode(_ data: Data) -> ImageContainer?

    func decodePartiallyDownloadedData(_ data: Data) -> ImageContainer?
}

public extension ImageDecoding {

    func decodePartiallyDownloadedData(_ data: Data) -> ImageContainer? {
        nil
    }
}

extension ImageDecoding {
    
    func decode(_ data: Data, urlResponse: URLResponse?, isCompleted: Bool) -> ImageResponse? {
        func _decode() -> ImageContainer? {
            if isCompleted {
                return decode(data)
            } else {
                return decodePartiallyDownloadedData(data)
            }
        }
        guard let container = autoreleasepool(invoking: _decode) else {
            return nil
        }
        return ImageResponse(container: container, urlResponse: urlResponse)
    }
}

public typealias ImageDecoder = ImageDecoders.Default

public enum ImageDecoders { }

public extension ImageDecoders {

    final class Default: ImageDecoding, ImageDecoderRegistering {

        var numberOfScans: Int { scanner.numberOfScans }
        private var scanner = ProgressiveJPEGScanner()

        public static let scanNumberKey = "ImageDecoders.Default.scanNumberKey"

        private var container: ImageContainer?

        public init() { }

        public init?(data: Data, context: ImageDecodingContext) {
            guard let container = _decode(data) else {
                return nil
            }
            self.container = container
        }

        public init?(partiallyDownloadedData data: Data, context: ImageDecodingContext) {

            guard ImageType(data) == .jpeg,
                ImageProperties.JPEG(data)?.isProgressive == true else {
                return nil
            }
        }
        
        private func drawPDFfromData(data: Data) -> PlatformImage? {

            guard let document = PDFDocument(data: data) else { return nil }
            guard let page = document.page(at: 0) else { return nil }

            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let img = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            return img
        }

        public func decode(_ data: Data) -> ImageContainer? {
            return container ?? _decode(data)
        }

        private func _decode(_ data: Data) -> ImageContainer? {
            
            let type = ImageType(data)
            var image: UIImage?
            
            if type == .pdf {
                image = drawPDFfromData(data: data)
            }
            else {
                image = ImageDecoders.Default._decode(data)
            }
            
            guard let imageRes = image else { return nil }
            var container = ImageContainer(image: imageRes)
            container.type = type

            if numberOfScans > 0 {
                container.userInfo[ImageDecoders.Default.scanNumberKey] = numberOfScans
            }
            return container
        }
        
        public func decodePartiallyDownloadedData(_ data: Data) -> ImageContainer? {
            guard let endOfScan = scanner.scan(data), endOfScan > 0 else {
                return nil
            }
            guard let image = ImageDecoder._decode(data[0...endOfScan]) else {
                return nil
            }
            return ImageContainer(image: image, type: .jpeg, isPreview: true, userInfo: [ImageDecoders.Default.scanNumberKey: numberOfScans])
        }
    }
}

private struct ProgressiveJPEGScanner {

    private(set) var numberOfScans = 0
    private var lastStartOfScan: Int = 0
    private var scannedIndex: Int = -1

    mutating func scan(_ data: Data) -> Int? {
        
        guard (scannedIndex + 1) < data.count else {
            return nil
        }

        var index = (scannedIndex + 1)
        var numberOfScans = self.numberOfScans
        while index < (data.count - 1) {
            scannedIndex = index

            if data[index] == 0xFF, data[index + 1] == 0xDA {
                lastStartOfScan = index
                numberOfScans += 1
            }
            index += 1
        }

        guard numberOfScans > self.numberOfScans else {
            return nil
        }
        
        self.numberOfScans = numberOfScans

        guard numberOfScans > 1 && lastStartOfScan > 0 else {
            return nil
        }

        return lastStartOfScan - 1
    }
}

extension ImageDecoders.Default {
    static func _decode(_ data: Data) -> PlatformImage? {
        return UIImage(data: data, scale: Screen.scale)
    }

}

public extension ImageDecoders {

    struct Empty: ImageDecoding {
        public let isProgressive: Bool

        public init(isProgressive: Bool = false) {
            self.isProgressive = isProgressive
        }

        public func decodePartiallyDownloadedData(_ data: Data) -> ImageContainer? {
            isProgressive ? ImageContainer(image: PlatformImage(), data: data, userInfo: [:]) : nil
        }

        public func decode(_ data: Data) -> ImageContainer? {
            ImageContainer(image: PlatformImage(), data: data, userInfo: [:])
        }
    }
}


public protocol ImageDecoderRegistering: ImageDecoding {

    init?(data: Data, context: ImageDecodingContext)
    
    init?(partiallyDownloadedData data: Data, context: ImageDecodingContext)
}

public extension ImageDecoderRegistering {

    init?(partiallyDownloadedData data: Data, context: ImageDecodingContext) {
        return nil
    }
}


public final class ImageDecoderRegistry {

    public static let shared = ImageDecoderRegistry()

    private struct Match {
        let closure: (ImageDecodingContext) -> ImageDecoding?
    }

    private var matches = [Match]()

    public init() {
        self.register(ImageDecoders.Default.self)
    }

    public func decoder(for context: ImageDecodingContext) -> ImageDecoding? {
        for match in matches {
            if let decoder = match.closure(context) {
                return decoder
            }
        }
        return nil
    }

    public func register<Decoder: ImageDecoderRegistering>(_ decoder: Decoder.Type) {
        register { context in
            if context.isCompleted {
                return decoder.init(data: context.data, context: context)
            } else {
                return decoder.init(partiallyDownloadedData: context.data, context: context)
            }
        }
    }

    public func register(_ match: @escaping (ImageDecodingContext) -> ImageDecoding?) {
        matches.insert(Match(closure: match), at: 0)
    }

    public func clear() {
        matches = []
    }
}


public struct ImageDecodingContext {
    
    public let request: DataRequest
    public let data: Data
    public let isCompleted: Bool
    public let urlResponse: URLResponse?

    public init(request: DataRequest, data: Data, isCompleted: Bool, urlResponse: URLResponse?) {
        self.request = request
        self.data = data
        self.isCompleted = isCompleted
        self.urlResponse = urlResponse
    }
}


public struct ImageType: ExpressibleByStringLiteral, Hashable {
   
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let png: ImageType = "public.png"
    public static let jpeg: ImageType = "public.jpeg"
    public static let pdf: ImageType = "public.pdf"
}


public extension ImageType {

    init?(_ data: Data) {
        guard let type = ImageType.make(data) else {
            return nil
        }
        self = type
    }

    private static func make(_ data: Data) -> ImageType? {
        func _match(_ numbers: [UInt8?]) -> Bool {
            guard data.count >= numbers.count else {
                return false
            }
            return zip(numbers.indices, numbers).allSatisfy { index, number in
                guard let number = number else { return true }
                return data[index] == number
            }
        }
        
        if _match([0x25, 0x50, 0x44, 0x46]) { return .pdf }
        
        if _match([0xFF, 0xD8, 0xFF]) { return .jpeg }

        if _match([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return .png }

        return nil
    }
}


enum ImageProperties {  }

extension ImageProperties {
    
    struct JPEG {
        public var isProgressive: Bool

        public init?(_ data: Data) {
            guard let isProgressive = ImageProperties.JPEG.isProgressive(data) else {
                return nil
            }
            self.isProgressive = isProgressive
        }

        private static func isProgressive(_ data: Data) -> Bool? {
            var index = 3
            while index < (data.count - 1) {

                if data[index] == 0xFF {
                    if data[index + 1] == 0xC2 {
                        return true
                    }
                    if data[index + 1] == 0xC0 {
                        return false
                    }
                }
                index += 1
            }
            return nil
        }
    }
}
