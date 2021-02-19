//
//  CameraOutputView.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 24/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MetalKit


class CameraOutputView: UIView {
 
    private var cameraView: CameraOutputRenderView?

    public init(captureSession: AVCaptureSession, outputOrientation: ExifOrientation) {
        
        self.orientation = outputOrientation
        
        super.init(frame: .zero)
        
        let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()

        let mtkView = metalDevice.flatMap { metalDevice in
            CameraOutputMTKView(
                captureSession: captureSession,
                outputOrientation: outputOrientation,
                device: metalDevice
            )
        }
        
        if let mtkView = mtkView {
            cameraView = mtkView
            addSubview(mtkView)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        cameraView?.frame = bounds
    }
    
    public var orientation: ExifOrientation {
        didSet {
            cameraView?.orientation = orientation
        }
    }
    
    public var onFrameDraw: (() -> ())? {
        didSet {
            cameraView?.onFrameDraw = onFrameDraw
        }
    }
}


final class CameraOutputMTKView: MTKView, CameraOutputRenderView, CameraCaptureOutputHandler {
    
    private var hasWindow = false
    private var bufferQueue = DispatchQueue.main
    private let ciContext: CIContext
    private var metalCommandQueue: MTLCommandQueue?
    
    var orientation: ExifOrientation
    var onFrameDraw: (() -> ())?
    
    var imageBuffer: CVImageBuffer? {
        didSet {
            if hasWindow {
                draw()
            }
        }
    }
    
    init(captureSession: AVCaptureSession, outputOrientation: ExifOrientation, device: MTLDevice) {
        
        ciContext = CIContext(mtlDevice: device, options: [CIContextOption.workingColorSpace: NSNull()])
        orientation = outputOrientation
        
        super.init(frame: .zero, device: device)

        clipsToBounds = true
        enableSetNeedsDisplay = false
        framebufferOnly = false
        isPaused = true
        
        metalCommandQueue = device.makeCommandQueue()
        bufferQueue = CaptureSessionPreviewService.startStreamingPreview(of: captureSession, to: self, isMirrored: outputOrientation.isMirrored)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        let hasWindow = (window != nil)
        
        bufferQueue.async { [weak self] in
            self?.hasWindow = hasWindow
        }
    }
    
    override func draw(_ rect: CGRect) {
       
        guard let imageBuffer = imageBuffer, let commandBuffer = metalCommandQueue?.makeCommandBuffer(), let currentDrawable = currentDrawable else { return }
        
        let image = CIImage(cvPixelBuffer: imageBuffer)
        
        let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)

        let scaleX = drawableSize.width / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
        let scale = min(scaleX, scaleY)

        let width = image.extent.width * scale
        let height = image.extent.height * scale
        let originX = (bounds.width - width) / 2
        let originY = (bounds.height - height) / 2

        let scaledImage = image
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: originX, y: originY))
        
        ciContext.render(scaledImage, to: currentDrawable.texture, commandBuffer: commandBuffer, bounds: bounds, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        
        onFrameDraw?()
    }
}
