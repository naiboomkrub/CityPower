//
//  CaptureSessionPreviewService.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit
import MetalKit

@objc public protocol CameraCaptureOutputHandler: class {
    var imageBuffer: CVImageBuffer? { get set }
}


final class CaptureSessionPreviewService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @discardableResult
    static func startStreamingPreview(of captureSession: AVCaptureSession, to handler: CameraCaptureOutputHandler,
        isMirrored: Bool = false) -> DispatchQueue {
        return service(for: captureSession, isMirrored: isMirrored).startStreamingPreview(to: handler)
    }
    
    func startStreamingPreview(to handler: CameraCaptureOutputHandler) -> DispatchQueue {
        queue.async { [weak self] in
            self?.handlers.append(WeakWrapper(value: handler))
        }
        return queue
    }
    
    @objc func captureOutput(_ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), !isInBackground {
            handlers.forEach { handlerWrapper in
                handlerWrapper.value?.imageBuffer = imageBuffer
            }
        }
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private static var sharedServices = NSMapTable<AVCaptureSession, CaptureSessionPreviewService>.weakToStrongObjects()
    
    private let queue = DispatchQueue(label: "com.CityPower.CaptureSessionPreviewService.queue")
    private var handlers = [WeakWrapper<CameraCaptureOutputHandler>]()
    private var isInBackground = false
    
    private init(captureSession: AVCaptureSession, isMirrored: Bool) {
        super.init()
        
        subscribeForAppStateChangeNotifications()
        setUpVideoDataOutput(for: captureSession, isMirrored: isMirrored)
    }
    
    private static func service(for captureSession: AVCaptureSession, isMirrored: Bool) -> CaptureSessionPreviewService {
        if let service = sharedServices.object(forKey: captureSession) {
            return service
        } else {
            let service = CaptureSessionPreviewService(captureSession: captureSession, isMirrored: isMirrored)
            sharedServices.setObject(service, forKey: captureSession)
            return service
        }
    }
    
    private func subscribeForAppStateChangeNotifications() {
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppWillResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func setUpVideoDataOutput(for captureSession: AVCaptureSession, isMirrored: Bool) {
        
        let captureOutput = AVCaptureVideoDataOutput()
        
        captureOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        captureOutput.setSampleBufferDelegate(self, queue: queue)
        
        do {
            try captureSession.configure {
                if captureSession.canAddOutput(captureOutput) {
                    captureSession.addOutput(captureOutput)
                }

                for connection in captureOutput.connections {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                        connection.isVideoMirrored = isMirrored
                    }
                }
            }
        } catch {
            debugPrint("Couldn't configure AVCaptureSession: \(error)")
        }
    }
    
    @objc private func handleAppWillResignActive(_: NSNotification) {
        queue.sync {
            glFinish()
            self.isInBackground = true
        }
    }
    
    @objc private func handleAppDidBecomeActive(_: NSNotification) {
        queue.async {
            self.isInBackground = false
        }
    }
}


extension AVCaptureSession {
    
    func configure(configuration: () throws -> ()) throws {
        beginConfiguration()
        try configuration()
        commitConfiguration()
    }
}


struct WeakWrapper<T: AnyObject> {
    
    weak var value: T?
    
    init(value: T) {
        self.value = value
    }
}


protocol CameraOutputRenderView: class {
    var frame: CGRect { get set }
    var orientation: ExifOrientation { get set }
    var onFrameDraw: (() -> ())? { get set }
}

