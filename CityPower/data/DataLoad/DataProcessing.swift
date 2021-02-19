//
//  DataProcessing.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


public protocol ImageProcessing {
    
    func process(_ image: PlatformImage) -> PlatformImage?

    func process(_ container: ImageContainer, context: ImageProcessingContext) -> ImageContainer?

    var identifier: String { get }
    var hashableIdentifier: AnyHashable { get }
}

public extension ImageProcessing {

    func process(_ container: ImageContainer, context: ImageProcessingContext) -> ImageContainer? {
        container.map(process)
    }

    var hashableIdentifier: AnyHashable { identifier }
}


public struct ImageProcessingContext {
    public let request: DataRequest
    public let response: ImageResponse
    public let isFinal: Bool

    public init(request: DataRequest, response: ImageResponse, isFinal: Bool) {
        self.request = request
        self.response = response
        self.isFinal = isFinal
    }
}

public enum ImageProcessors {}

extension ImageProcessors {

    public struct Resize: ImageProcessing, Hashable, CustomStringConvertible {
        private let size: Size
        private let contentMode: ContentMode
        private let crop: Bool
        private let upscale: Bool

        public enum ContentMode: CustomStringConvertible {
            case aspectFill
            case aspectFit

            public var description: String {
                switch self {
                case .aspectFill: return ".aspectFill"
                case .aspectFit: return ".aspectFit"
                }
            }
        }

        public init(size: CGSize, unit: ImageProcessingOptions.Unit = .points, contentMode: ContentMode = .aspectFill, crop: Bool = false, upscale: Bool = false) {
            self.size = Size(cgSize: CGSize(size: size, unit: unit))
            self.contentMode = contentMode
            self.crop = crop
            self.upscale = upscale
        }

        public init(width: CGFloat, unit: ImageProcessingOptions.Unit = .points, upscale: Bool = false) {
            self.init(size: CGSize(width: width, height: 9999), unit: unit, contentMode: .aspectFit, crop: false, upscale: upscale)
        }

        public init(height: CGFloat, unit: ImageProcessingOptions.Unit = .points, upscale: Bool = false) {
            self.init(size: CGSize(width: 9999, height: height), unit: unit, contentMode: .aspectFit, crop: false, upscale: upscale)
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            if crop && contentMode == .aspectFill {
                return image.processed.byResizingAndCropping(to: size.cgSize)
            } else {
                return image.processed.byResizing(to: size.cgSize, contentMode: contentMode, upscale: upscale)
            }
        }

        public var identifier: String {
            "com.CityPower/resize?s=\(size.cgSize),cm=\(contentMode),crop=\(crop),upscale=\(upscale)"
        }

        public var hashableIdentifier: AnyHashable { self }

        public var description: String {
            "Resize(size: \(size.cgSize) pixels, contentMode: \(contentMode), crop: \(crop), upscale: \(upscale))"
        }
    }
}

extension ImageProcessors {

    public struct Circle: ImageProcessing, Hashable, CustomStringConvertible {
        private let border: ImageProcessingOptions.Border?

        public init(border: ImageProcessingOptions.Border? = nil) {
            self.border = border
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            image.processed.byDrawingInCircle(border: border)
        }

        public var identifier: String {
            if let border = self.border {
                return "com.CityPower/circle?border=\(border)"
            } else {
                return "com.CityPower/circle"
            }
        }

        public var hashableIdentifier: AnyHashable { self }

        public var description: String {
            "Circle(border: \(border?.description ?? "nil"))"
        }
    }
}


extension ImageProcessors {

    public struct RoundedCorners: ImageProcessing, Hashable, CustomStringConvertible {
        private let radius: CGFloat
        private let border: ImageProcessingOptions.Border?

        public init(radius: CGFloat, unit: ImageProcessingOptions.Unit = .points, border: ImageProcessingOptions.Border? = nil) {
            self.radius = radius.converted(to: unit)
            self.border = border
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            image.processed.byAddingRoundedCorners(radius: radius, border: border)
        }

        public var identifier: String {
            if let border = self.border {
                return "com.CityPower/rounded_corners?radius=\(radius),border=\(border)"
            } else {
                return "com.CityPower/rounded_corners?radius=\(radius)"
            }
        }

        public var hashableIdentifier: AnyHashable { self }

        public var description: String {
            "RoundedCorners(radius: \(radius) pixels, border: \(border?.description ?? "nil"))"
        }
    }
}


struct ImageDecompression {

    static func decompress(image: PlatformImage) -> PlatformImage {
        let output = image.decompressed() ?? image
        ImageDecompression.setDecompressionNeeded(false, for: output)
        return output
    }

    static var isDecompressionNeededAK = "ImageDecompressor.isDecompressionNeeded.AssociatedKey"

    static func setDecompressionNeeded(_ isDecompressionNeeded: Bool, for image: PlatformImage) {
        objc_setAssociatedObject(image, &isDecompressionNeededAK, isDecompressionNeeded, .OBJC_ASSOCIATION_RETAIN)
    }

    static func isDecompressionNeeded(for image: PlatformImage) -> Bool? {
        objc_getAssociatedObject(image, &isDecompressionNeededAK) as? Bool
    }
}


extension ImageProcessors {

    public struct Composition: ImageProcessing, Hashable, CustomStringConvertible {
        let processors: [ImageProcessing]

        public init(_ processors: [ImageProcessing]) {
            self.processors = processors
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            processors.reduce(image) { image, processor in
                autoreleasepool {
                    image.flatMap { processor.process($0) }
                }
            }
        }

        public func process(_ container: ImageContainer, context: ImageProcessingContext) -> ImageContainer? {
            processors.reduce(container) { container, processor in
                autoreleasepool {
                    container.flatMap { processor.process($0, context: context) }
                }
            }
        }

        public var identifier: String {
            processors.map({ $0.identifier }).joined()
        }

        public var hashableIdentifier: AnyHashable { self }

        public func hash(into hasher: inout Hasher) {
            for processor in processors {
                hasher.combine(processor.hashableIdentifier)
            }
        }

        public static func == (lhs: Composition, rhs: Composition) -> Bool {
            lhs.processors == rhs.processors
        }

        public var description: String {
            "Composition(processors: \(processors))"
        }
    }
}

extension ImageProcessors {

    public struct Anonymous: ImageProcessing, CustomStringConvertible {
        public let identifier: String
        private let closure: (PlatformImage) -> PlatformImage?

        public init(id: String, _ closure: @escaping (PlatformImage) -> PlatformImage?) {
            self.identifier = id
            self.closure = closure
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            self.closure(image)
        }

        public var description: String {
            "AnonymousProcessor(identifier: \(identifier)"
        }
    }
}

private extension PlatformImage {

    func draw(inCanvasWithSize canvasSize: CGSize, drawRect: CGRect? = nil) -> PlatformImage? {
        guard let cgImage = cgImage else {
            return nil
        }
        guard let ctx = CGContext.make(cgImage, size: canvasSize) else {
            return nil
        }
        ctx.draw(cgImage, in: drawRect ?? CGRect(origin: .zero, size: canvasSize))
        guard let outputCGImage = ctx.makeImage() else {
            return nil
        }
        return PlatformImage.make(cgImage: outputCGImage, source: self)
    }

    func decompressed() -> PlatformImage? {
        guard let cgImage = cgImage else {
            return nil
        }
        return draw(inCanvasWithSize: cgImage.size, drawRect: CGRect(origin: .zero, size: cgImage.size))
    }
}

private extension PlatformImage {
    var processed: ImageProcessingExtensions {
        ImageProcessingExtensions(image: self)
    }
}

private struct ImageProcessingExtensions {
    
    let image: PlatformImage

    func byResizing(to targetSize: CGSize,
                    contentMode: ImageProcessors.Resize.ContentMode,
                    upscale: Bool) -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let targetSize = targetSize.rotatedForOrientation(image.imageOrientation)
        let scale = cgImage.size.getScale(targetSize: targetSize, contentMode: contentMode)
        
        guard scale < 1 || upscale else {
            return image
        }
        let size = cgImage.size.scaled(by: scale).rounded()
        return image.draw(inCanvasWithSize: size)
    }

    func byResizingAndCropping(to targetSize: CGSize) -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let targetSize = targetSize.rotatedForOrientation(image.imageOrientation)
        let scale = cgImage.size.getScale(targetSize: targetSize, contentMode: .aspectFill)
        let scaledSize = cgImage.size.scaled(by: scale)
        let drawRect = scaledSize.centeredInRectWithSize(targetSize)
        return image.draw(inCanvasWithSize: targetSize, drawRect: drawRect)
    }

    func byDrawingInCircle(border: ImageProcessingOptions.Border?) -> PlatformImage? {
        guard let squared = byCroppingToSquare(), let cgImage = squared.cgImage else {
            return nil
        }
        let radius = CGFloat(cgImage.width) / 2.0
        return squared.processed.byAddingRoundedCorners(radius: radius, border: border)
    }

    func byCroppingToSquare() -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        guard cgImage.width != cgImage.height else {
            return image
        }

        let imageSize = cgImage.size
        let side = min(cgImage.width, cgImage.height)
        let targetSize = CGSize(width: side, height: side)
        let cropRect = CGRect(origin: .zero, size: targetSize).offsetBy(
            dx: max(0, (imageSize.width - targetSize.width) / 2),
            dy: max(0, (imageSize.height - targetSize.height) / 2)
        )
        guard let cropped = cgImage.cropping(to: cropRect) else {
            return nil
        }
        return PlatformImage.make(cgImage: cropped, source: image)
    }

    func byAddingRoundedCorners(radius: CGFloat, border: ImageProcessingOptions.Border? = nil) -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        guard let ctx = CGContext.make(cgImage, size: cgImage.size, alphaInfo: .premultipliedLast) else {
            return nil
        }
        let rect = CGRect(origin: CGPoint.zero, size: cgImage.size)
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.clip()
        ctx.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: cgImage.size))

        if let border = border {
            ctx.setStrokeColor(border.color.cgColor)
            ctx.addPath(path)
            ctx.setLineWidth(border.width)
            ctx.strokePath()
        }
        guard let outputCGImage = ctx.makeImage() else {
            return nil
        }
        return PlatformImage.make(cgImage: outputCGImage, source: image)
    }
}

typealias Color = UIColor

extension UIImage {
    static func make(cgImage: CGImage, source: UIImage) -> UIImage {
        UIImage(cgImage: cgImage, scale: source.scale, orientation: source.imageOrientation)
    }
}


extension CGImage {

    var isOpaque: Bool {
        let alpha = alphaInfo
        return alpha == .none || alpha == .noneSkipFirst || alpha == .noneSkipLast
    }
    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

private extension CGFloat {
    func converted(to unit: ImageProcessingOptions.Unit) -> CGFloat {
        switch unit {
        case .pixels: return self
        case .points: return self * Screen.scale
        }
    }
}

private struct Size: Hashable {
    let cgSize: CGSize

    func hash(into hasher: inout Hasher) {
        hasher.combine(cgSize.width)
        hasher.combine(cgSize.height)
    }
}

private extension CGSize {
    init(size: CGSize, unit: ImageProcessingOptions.Unit) {
        switch unit {
        case .pixels: self = size
        case .points: self = size.scaled(by: Screen.scale)
        }
    }

    func scaled(by scale: CGFloat) -> CGSize {
        CGSize(width: width * scale, height: height * scale)
    }

    func rounded() -> CGSize {
        CGSize(width: CGFloat(round(width)), height: CGFloat(round(height)))
    }
}

private extension CGSize {
    func rotatedForOrientation(_ imageOrientation: UIImage.Orientation) -> CGSize {
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: height, height: width)
        case .up, .upMirrored, .down, .downMirrored:
            return self
        @unknown default:
            return self
        }
    }
}

extension CGSize {
    func getScale(targetSize: CGSize, contentMode: ImageProcessors.Resize.ContentMode) -> CGFloat {
        let scaleHor = targetSize.width / width
        let scaleVert = targetSize.height / height

        switch contentMode {
        case .aspectFill:
            return max(scaleHor, scaleVert)
        case .aspectFit:
            return min(scaleHor, scaleVert)
        }
    }

    func centeredInRectWithSize(_ targetSize: CGSize) -> CGRect {

        CGRect(origin: .zero, size: self).offsetBy(
            dx: -(width - targetSize.width) / 2,
            dy: -(height - targetSize.height) / 2
        )
    }
}


func == (lhs: [ImageProcessing], rhs: [ImageProcessing]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    return zip(lhs, rhs).allSatisfy {
        $0.hashableIdentifier == $1.hashableIdentifier
    }
}

public enum ImageProcessingOptions {

    public enum Unit: CustomStringConvertible {
        case points
        case pixels

        public var description: String {
            switch self {
            case .points: return "points"
            case .pixels: return "pixels"
            }
        }
    }

    public struct Border: Hashable, CustomStringConvertible {
        public let color: UIColor
        public let width: CGFloat

        public init(color: UIColor, width: CGFloat = 1, unit: Unit = .points) {
            self.color = color
            self.width = width.converted(to: unit)
        }

        public var description: String {
            "Border(color: \(color.hex), width: \(width) pixels)"
        }
    }
}


struct Screen {
    static var scale: CGFloat { UIScreen.main.scale }
}

extension Color {
    var hex: String {
        var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let components = [r, g, b, a < 1 ? a : nil]
        return "#" + components
            .compactMap { $0 }
            .map { String(format: "%02lX", lroundf(Float($0) * 255)) }
            .joined()
    }
}

private extension CGContext {
    static func make(_ image: CGImage, size: CGSize, alphaInfo: CGImageAlphaInfo? = nil) -> CGContext? {
        let alphaInfo: CGImageAlphaInfo = alphaInfo ?? (image.isOpaque ? .noneSkipLast : .premultipliedLast)

        if let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: alphaInfo.rawValue
        ) {
            return ctx
        }

        return CGContext(
            data: nil,
            width: Int(size.width), height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: alphaInfo.rawValue
        )
    }
}
