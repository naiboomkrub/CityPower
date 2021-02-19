//
//  PhotoTweakView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import UIKit

final class PhotoTweakView: UIView, UIScrollViewDelegate {
    
    private let scrollView = PhotoScrollView()
    private let gridView = GridView()
    
    private let topMask = UIView()
    private let bottomMask = UIView()
    private let leftMask = UIView()
    private let rightMask = UIView()
    
    private var cropSize: CGSize = .zero
    private var originalSize: CGSize = .zero
    private var originalPoint: CGPoint = .zero
    private var manuallyZoomed: Bool = false

    private var turnAngle: CGFloat = 0
    private var tiltAngle: CGFloat = 0
    
    private var angle: CGFloat {
        return turnAngle + tiltAngle }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.bounces = true
        scrollView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 10
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        
        let maskColor = UIColor.Gray6.withAlphaComponent(0.9)
        
        topMask.backgroundColor = maskColor
        bottomMask.backgroundColor = maskColor
        leftMask.backgroundColor = maskColor
        rightMask.backgroundColor = maskColor
        
        gridView.isUserInteractionEnabled = false
        gridView.isHidden = true
        
        addSubview(scrollView)
        addSubview(gridView)
        addSubview(topMask)
        addSubview(bottomMask)
        addSubview(leftMask)
        addSubview(rightMask)
        
        updateMasks()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        didSet {
            resetScrollViewState()
            calculateFrames()
            adjustRotation()
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return scrollView
    }
    
    var cropAspectRatio = CGFloat(AspectRatio.defaultRatio.widthToHeightRatio()) {
        didSet {
            if cropAspectRatio != oldValue && setTime > 0 {
                resetScale()
                calculateFrames()
                notifyAboutCroppingParametersChange()
            } else {
                setTime += 1
            }
        }
    }
    
    var setTime: Int = 0
    var onCroppingParametersChange: ((ImageCroppingParameters) -> ())?
    
    func setImage(_ image: UIImage) {
        scrollView.imageView.image = image
        resetScale()
        calculateFrames()
        notifyAboutCroppingParametersChange()
    }
    
    private func adjustRotation() {
        adjustRotation(contentOffsetCenter: contentOffsetCenter())
    }
    
    private func adjustRotation(contentOffsetCenter: CGPoint) {
        
        let width = abs(cos(angle)) * cropSize.width + abs(sin(angle)) * cropSize.height
        let height = abs(sin(angle)) * cropSize.width + abs(cos(angle)) * cropSize.height
        let center = scrollView.center
        
        let newBounds = CGRect(x: 0, y: 0, width: width, height: height)
        let newContentOffset = CGPoint(
            x: contentOffsetCenter.x - newBounds.size.width / 2,
            y: contentOffsetCenter.y - newBounds.size.height / 2
        )
        
        scrollView.transform = CGAffineTransform(rotationAngle: angle)
        scrollView.bounds = newBounds
        scrollView.center = center
        scrollView.contentOffset = newContentOffset
        
        let shouldScale = scrollView.contentSize.width / scrollView.bounds.size.width <= 1.0 || self.scrollView.contentSize.height / self.scrollView.bounds.size.height <= 1.0
        
        if !manuallyZoomed || shouldScale {
            
            scrollView.minimumZoomScale = scrollView.zoomScaleToBound()
            scrollView.zoomScale = scrollView.minimumZoomScale
            
            manuallyZoomed = false
        }
        
        checkScrollViewContentOffset()
        notifyAboutCroppingParametersChange()
    }
    
    private func contentOffsetCenter() -> CGPoint {
        return CGPoint(
            x: scrollView.contentOffset.x + scrollView.bounds.size.width / 2,
            y: scrollView.contentOffset.y + scrollView.bounds.size.height / 2
        )
    }
    
    func setCroppingParameters(_ parameters: ImageCroppingParameters) {
        
        scrollView.zoomScale = parameters.zoomScale
        manuallyZoomed = parameters.manuallyZoomed
        
        turnAngle = parameters.turnAngle
        tiltAngle = parameters.tiltAngle
        
        adjustRotation(contentOffsetCenter: parameters.contentOffsetCenter)
    }
    
    func setTiltAngle(_ angleInRadians: Float) {
        tiltAngle = CGFloat(angleInRadians)
        adjustRotation()
    }
    
    func turnCounterclockwise() {
        turnAngle += CGFloat(Float(-90).degreesToRadians())
        adjustRotation()
    }
    
    func photoTranslation() -> CGPoint {
        let imageViewBounds = scrollView.imageView.bounds
        let rect = scrollView.imageView.convert(imageViewBounds, to: self)
        let point = CGPoint(x: rect.midX, y: rect.midY)
        return CGPoint(x: point.x - center.x, y: point.y - center.y)
    }
    
    func setGridVisible(_ visible: Bool) {
        gridView.isHidden = !visible
    }
    
    func cropPreviewImage() -> CGImage? {
        
        let gridWasHidden = gridView.isHidden
        gridView.isHidden = true
        
        let previewImage = snapshot().flatMap { snapshot -> CGImage? in
            
            let cropRect = CGRect(
                x: (bounds.origin.x + (bounds.size.width - cropSize.width) / 2) * snapshot.scale,
                y: (bounds.origin.y + (bounds.size.height - cropSize.height) / 2) * snapshot.scale,
                width: cropSize.width * snapshot.scale,
                height: cropSize.height * snapshot.scale
            )
            
            return snapshot.cgImage.flatMap { $0.cropping(to: cropRect) }
        }
        
        gridView.isHidden = gridWasHidden
        
        return previewImage
    }

    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.scrollView.imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        manuallyZoomed = true
        notifyAboutCroppingParametersChange()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            notifyAboutCroppingParametersChange()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        notifyAboutCroppingParametersChange()
    }
    
    private func calculateFrames() {
        
        guard let image = scrollView.imageView.image, bounds.width > 0 && bounds.height > 0 else { return }
        
        cropSize = CGSize(width: bounds.size.width, height: bounds.size.width / cropAspectRatio)
        
        if cropSize.height > bounds.size.height {
            cropSize = cropSize.scaled(bounds.size.height / cropSize.height)
        }
        
        let scaleX = image.size.width / cropSize.width
        let scaleY = image.size.height / cropSize.height
        let scale = min(scaleX, scaleY)
        
        let minZoomBounds = CGRect(x: 0, y: 0,
            width: image.size.width / scale,
            height: image.size.height / scale
        )
        
        originalSize = minZoomBounds.size
        
        scrollView.bounds = minZoomBounds
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
        scrollView.center = center
        
        //let minSize = min(scrollView.bounds.size.width, scrollView.bounds.size.height)
        //scrollView.contentInset = UIEdgeInsets(top: (scrollView.bounds.size.height - minSize) / 2, left: (scrollView.bounds.size.width - minSize) / 2, bottom: (scrollView.bounds.size.height - minSize) / 2, right: (scrollView.bounds.size.width - minSize) / 2)
        
        scrollView.imageView.frame = CGRect(
            x: scrollView.bounds.origin.x,
            y: scrollView.bounds.origin.y,
            width: scrollView.bounds.size.width,
            height: scrollView.bounds.size.height
        )
        
        gridView.bounds = CGRect(origin: .zero, size: cropSize)
        gridView.center = center
        
        originalPoint = convert(scrollView.center, to: self)
        
        updateMasks()
    }
    
    private func updateMasks(animated: Bool = false) {
        
        let horizontalMaskSize = CGSize(
            width: bounds.size.width,
            height: (bounds.size.height - cropSize.height) / 2)
        
        let verticalMaskSize = CGSize(
            width: (bounds.size.width - cropSize.width) / 2,
            height: bounds.size.height - horizontalMaskSize.height)
        
        let animation = {
            self.topMask.frame = CGRect(
                origin: CGPoint(x: self.bounds.origin.x, y: self.bounds.origin.y),
                size: horizontalMaskSize)
            self.bottomMask.frame = CGRect(
                origin: CGPoint(x: self.bounds.origin.x, y: self.bounds.maxY - horizontalMaskSize.height),
                size: horizontalMaskSize)
            self.leftMask.frame = CGRect(
                origin: CGPoint(x: self.bounds.origin.x, y: self.topMask.bounds.maxY),
                size: verticalMaskSize)
            self.rightMask.frame = CGRect(
                origin: CGPoint(x: self.bounds.maxX - verticalMaskSize.width, y: self.topMask.bounds.maxY),
                size: verticalMaskSize)
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: animation)
        } else {
            animation()
        }
    }
    
    private func checkScrollViewContentOffset() {
        
        scrollView.contentOffset.x = max(scrollView.contentOffset.x, 0)
        scrollView.contentOffset.y = max(scrollView.contentOffset.y, 0)
        
        if scrollView.contentSize.height - scrollView.contentOffset.y <= scrollView.bounds.size.height {
            scrollView.contentOffset.y = scrollView.contentSize.height - scrollView.bounds.size.height
        }
        
        if scrollView.contentSize.width - scrollView.contentOffset.x <= scrollView.bounds.size.width {
            scrollView.contentOffset.x = scrollView.contentSize.width - scrollView.bounds.size.width
        }
    }
    
    private func resetScrollViewState() {
        scrollView.transform = .identity
        scrollView.minimumZoomScale = 1
        resetScale()
    }
    
    private func resetScale() {
        scrollView.zoomScale = 1
    }
    
    private func notifyAboutCroppingParametersChange() {
        onCroppingParametersChange?(croppingParameters())
    }
    
    private func croppingParameters() -> ImageCroppingParameters {
        
        var transform = CGAffineTransform.identity
        
        let translation = photoTranslation()
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        transform = transform.rotated(by: angle)
        
        let t = scrollView.imageView.transform
        let xScale = sqrt(t.a * t.a + t.c * t.c)
        let yScale = sqrt(t.b * t.b + t.d * t.d)
        transform = transform.scaledBy(x: xScale, y: yScale)
        
        let parameters = ImageCroppingParameters(
            transform: transform,
            sourceSize: scrollView.imageView.image?.size ?? .zero,
            sourceOrientation: scrollView.imageView.image?.imageOrientation.exifOrientation ?? .up,
            outputWidth: scrollView.imageView.image?.size.width ?? 0,
            cropSize: cropSize,
            imageViewSize: scrollView.imageView.bounds.size,
            contentOffsetCenter: contentOffsetCenter(),
            turnAngle: turnAngle,
            tiltAngle: tiltAngle,
            zoomScale: scrollView.zoomScale,
            manuallyZoomed: manuallyZoomed
        )
        
        return parameters
    }
}

private class PhotoScrollView: UIScrollView {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func zoomScaleToBound() -> CGFloat {
        if imageView.bounds.size.width > 0 && imageView.bounds.size.height > 0 {
            let widthScale = bounds.size.width / imageView.bounds.size.width
            let heightScale = bounds.size.height / imageView.bounds.size.height
            return max(widthScale, heightScale)
        } else {
            return 1
        }
    }
}



extension Float {
    
    func degreesToRadians() -> Float {
        return self * .pi / 180
    }
    
    func radiansToDegrees() -> Float {
        return self * 180 / .pi
    }
}

extension UIView {
    
    func snapshot() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            self.layer.render(in: rendererContext.cgContext)
        }
    }
}


public extension UIImage.Orientation {
    var exifOrientation: ExifOrientation {
        switch self {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .rightMirrored
        case .left:
            return .right
        case .rightMirrored:
            return .leftMirrored
        case .right:
            return .left
        @unknown default:
            assertionFailure("Unknown `UIImage.Orientation`, assuming `.up`")
            return .up
        }
    }
}

public enum ExifOrientation: Int {
    
    case up = 1
    case upMirrored = 2
    case down = 3
    case downMirrored = 4
    case leftMirrored = 5
    case left = 6
    case rightMirrored = 7
    case right = 8
    
    public var dimensionsSwapped: Bool {
        switch self {
        case .leftMirrored, .left, .rightMirrored, .right:
            return true
        default:
            return false
        }
    }
    
    public var isMirrored: Bool {
        switch self {
        case .leftMirrored, .upMirrored, .rightMirrored, .downMirrored:
            return true
        default:
            return false
        }
    }
}


public extension CGImage {
    
    func imageFixedForOrientation(_ orientation: ExifOrientation) -> CGImage? {
        
        let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: false])
        let ciImage = CIImage(cgImage: self).oriented(forExifOrientation: Int32(orientation.rawValue))
        
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }
    
    func scaled(_ scale: CGFloat) -> CGImage? {
        
        let outputWidth = Int(CGFloat(width) * scale)
        let outputHeight = Int(CGFloat(height) * scale)
        
        guard let colorSpace: CGColorSpace = {
            if let colorSpace = colorSpace, colorSpace.model != .indexed {
                return colorSpace
            } else {
                return CGColorSpaceCreateDeviceRGB()
            }
        }() else {
            return nil
        }
        
        guard let context = CGContext(
            data: nil,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(origin: .zero, size: CGSize(width: outputWidth, height: outputHeight)))
        
        return context.makeImage()
    }
    
    func resized(toFit size: CGSize) -> CGImage? {
        
        let sourceWidth = CGFloat(width)
        let sourceHeight = CGFloat(height)
        
        if sourceWidth > 0 && sourceHeight > 0 {
            return scaled(min(size.width / sourceWidth, size.height / sourceHeight))
        } else {
            return nil
        }
    }
    
    func resized(toFill size: CGSize) -> CGImage? {
        
        let sourceWidth = CGFloat(width)
        let sourceHeight = CGFloat(height)
        
        if sourceWidth > 0 && sourceHeight > 0 {
            return scaled(max(size.width / sourceWidth, size.height / sourceHeight))
        } else {
            return nil
        }
    }
}


extension CGSize {
    
    func intersection(_ other: CGSize) -> CGSize {
        return CGSize(
            width: min(width, other.width),
            height: min(height, other.height)
        )
    }
    
    func intersectionWidth(_ width: CGFloat) -> CGSize {
        return CGSize(
            width: min(self.width, width),
            height: height
        )
    }
    
    func scaled(_ scale: CGFloat) -> CGSize {
        return CGSize(width: width * scale, height: height * scale)
    }
}

