//
//  CameraService.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 24/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import Photos
import UIKit
import CoreMotion


public protocol CameraService: class {
    
    var isFlashAvailable: Bool { get }
    var isFlashEnabled: Bool { get }
    
    func getCaptureSession(completion: @escaping (AVCaptureSession?) -> ())
    func getOutputOrientation(completion: @escaping (ExifOrientation) -> ())

    func setFlashEnabled(_: Bool) -> Bool
    
    func takePhoto(completion: @escaping (PhotoFromCamera?) -> ())
    func takePhotoToPhotoLibrary(croppedToRatio: CGFloat?, completion: @escaping (PhotoLibraryItem?) -> ())
    
    func setCaptureSessionRunning(_: Bool)
    
    func focusOnPoint(_ focusPoint: CGPoint) -> Bool
    
    func canToggleCamera(completion: @escaping (Bool) -> ())
    func toggleCamera(completion: @escaping (_ newOutputOrientation: ExifOrientation) -> ())
}


public struct PhotoFromCamera {
    let path: String
}


public final class CameraServiceImpl: NSObject, CameraService, AVCapturePhotoCaptureDelegate {
    
    private struct Error: Swift.Error {}
    
    private var imageStorage: ImageStorage
    private var captureSession: AVCaptureSession?
    private var output: AVCapturePhotoOutput?
    private var setting: AVCapturePhotoSettings?
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var photoResult: AVCapturePhoto?
    private var flashOn: Bool?
    
    private var orientationPic: UIInterfaceOrientation?
    private var motionManager: CMMotionManager?
    
    private var activeCamera: AVCaptureDevice? {
        return camera(for: activeCameraType)
    }
    
    private var activeCameraType: CameraType

    public init(initialActiveCameraType: CameraType, imageStorage: ImageStorage) {

        self.imageStorage = imageStorage
        
        backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        motionManager = CMMotionManager()
        
        self.activeCameraType = initialActiveCameraType
    }
    
    deinit {
        self.motionManager = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    public func getCaptureSession(completion: @escaping (AVCaptureSession?) -> ()) {
        
        func callCompletionOnMainQueue(with session: AVCaptureSession?) {
            DispatchQueue.main.async {
                completion(session)
            }
        }
        
        addCoreMotion()
        captureSessionSetupQueue.async { [weak self] in
            
            if let captureSession = self?.captureSession {
                callCompletionOnMainQueue(with: captureSession)
                
            } else {
                
                let mediaType = AVMediaType.video
                
                switch AVCaptureDevice.authorizationStatus(for: mediaType) {
                    
                case .authorized:
                    self?.setUpCaptureSession()
                    callCompletionOnMainQueue(with: self?.captureSession)
                    
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: mediaType) { granted in
                        self?.captureSessionSetupQueue.async {
                            if let captureSession = self?.captureSession {
                                callCompletionOnMainQueue(with: captureSession)
                            } else if granted {
                                self?.setUpCaptureSession()
                                callCompletionOnMainQueue(with: self?.captureSession)
                            } else {
                                callCompletionOnMainQueue(with: nil)
                            }
                        }
                    }
                    
                case .restricted, .denied:
                    callCompletionOnMainQueue(with: nil)
                    
                @unknown default:
                    assertionFailure("Unknown authorization status")
                    callCompletionOnMainQueue(with: nil)
                }
            }
        }
    }
    
    public func getOutputOrientation(completion: @escaping (ExifOrientation) -> ()) {
        completion(outputOrientationForCamera(activeCamera))
    }
    
    private func setUpCaptureSession() {
        
        do {
            
            #if arch(i386) || arch(x86_64)
                throw Error()
            #endif
            
            guard let activeCamera = activeCamera else { return }
            
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            
            try CameraServiceImpl.configureCamera(backCamera)
            
            let input = try AVCaptureDeviceInput(device: activeCamera)
            
            let output = AVCapturePhotoOutput()

            if captureSession.canAddInput(input) && captureSession.canAddOutput(output) {
                captureSession.addInput(input)
                captureSession.addOutput(output)
            } else {
                throw Error()
            }
            
            captureSession.startRunning()
            
            self.output = output
            self.captureSession = captureSession
            self.flashOn = false
            
            subscribeForNotifications(session: captureSession)
            
        } catch {
            self.output = nil
            self.captureSession = nil
            self.flashOn = false
        }
    }
    
    private func subscribeForNotifications(session: AVCaptureSession) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: session
        )
    }
    
    private var shouldRestartSessionAfterInterruptionEnds = false
    
    @objc private func sessionWasInterrupted(notification: NSNotification) {
        shouldRestartSessionAfterInterruptionEnds = (captureSession?.isRunning == true)
    }
    
    @objc private func sessionInterruptionEnded(notification: NSNotification) {
        if shouldRestartSessionAfterInterruptionEnds && captureSession?.isRunning == false {
            captureSessionSetupQueue.async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    @objc private func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        print(error)
    }
    
    
    public func setCaptureSessionRunning(_ needsRunning: Bool) {
        captureSessionSetupQueue.async {
            if needsRunning {
                self.captureSession?.startRunning()
            } else {
                self.captureSession?.stopRunning()
            }
        }
    }
    
    public func focusOnPoint(_ focusPoint: CGPoint) -> Bool {
        guard let activeCamera = self.activeCamera,
            activeCamera.isFocusPointOfInterestSupported || activeCamera.isExposurePointOfInterestSupported else {
            return false
        }
        
        do {
            try activeCamera.lockForConfiguration()
            
            if activeCamera.isFocusPointOfInterestSupported {
                activeCamera.focusPointOfInterest = focusPoint
                activeCamera.focusMode = .continuousAutoFocus
            }
            
            if activeCamera.isExposurePointOfInterestSupported {
                activeCamera.exposurePointOfInterest = focusPoint
                activeCamera.exposureMode = .continuousAutoExposure
            }
            
            activeCamera.unlockForConfiguration()
            
            return true
        }
        catch {
            debugPrint("Couldn't focus camera: \(error)")
            return false
        }
    }
    
    public func canToggleCamera(completion: @escaping (Bool) -> ()) {
        completion(frontCamera != nil && backCamera != nil)
    }
    
    public func toggleCamera(completion: @escaping (_ newOutputOrientation: ExifOrientation) -> ()) {
        guard let captureSession = captureSession else { return }
        
        do {
            
            let targetCameraType: CameraType = (activeCamera == backCamera) ? .front : .back
            
            guard let targetCamera = camera(for: targetCameraType) else {
                throw Error()
            }
            
            let newInput = try AVCaptureDeviceInput(device: targetCamera)
            
            try captureSession.configure {
                
                captureSession.inputs.forEach { captureSession.removeInput($0) }
                captureSession.sessionPreset = .high
                
                if captureSession.canAddInput(newInput) {
                    captureSession.addInput(newInput)
                }
                
                captureSession.sessionPreset = .photo
                
                setupOrientationFor(captureSession: captureSession, cameraType: targetCameraType)
                
                try CameraServiceImpl.configureCamera(targetCamera)
            }
            
            activeCameraType = targetCameraType
            
        } catch {
            debugPrint("Couldn't toggle camera: \(error)")
        }
        
        completion(outputOrientationForCamera(activeCamera))
    }
    
    public var isFlashAvailable: Bool {
        return backCamera?.isFlashAvailable == true
    }
    
    public var isFlashEnabled: Bool {
        return setting?.flashMode == .on
    }
    
    private func setupOrientationFor(captureSession: AVCaptureSession?, cameraType: CameraType) {
        guard let captureSession = captureSession else { return }
        
        for captureOutput in captureSession.outputs {
            for connection in captureOutput.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                    connection.isVideoMirrored = cameraType == .front
                }
            }
        }
    }
    
    public func setFlashEnabled(_ enabled: Bool) -> Bool {
        
        guard let camera = backCamera else { return false }
        
            if camera.hasFlash && enabled {
                self.flashOn = true
            } else {
                self.flashOn = false
            }
            return true
    }

    private var completionHandler: () -> () = {}
    
    public func takePhoto(completion: @escaping (PhotoFromCamera?) -> ()) {
        guard let output = output, let flashOn = flashOn else {
            completion(nil)
            return
        }
        
        let setting = AVCapturePhotoSettings()
        setting.livePhotoVideoCodecType = .jpeg
        
        if flashOn {
            setting.flashMode = .on
        }
        output.capturePhoto(with: setting, delegate: self)
        
        completionHandler = { [weak self] in
            
            if let dataImage = self?.photoResult?.cgImageRepresentation()?.takeUnretainedValue() {
                
                var ciImage = CIImage(cgImage: dataImage)
            
                switch self?.orientationPic {
                    case .landscapeRight:
                        ciImage = ciImage.oriented(forExifOrientation: 1)
                    case .landscapeLeft:
                        ciImage = ciImage.oriented(forExifOrientation: 3)
                    default:
                        ciImage = ciImage.oriented(forExifOrientation: 6)
                }
                
                let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent)
                
                self?.imageStorage.save(cgImage: cgImage, callbackQueue: .main) { path in
                    guard let path = path else {
                        completion(nil)
                        return
                    }
                    completion(PhotoFromCamera(path: path))
                }

            } else {
                completion(nil)
            }
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Swift.Error?) {
        
        self.photoResult = photo
        completionHandler()
    }
        
    public func takePhotoToPhotoLibrary(croppedToRatio cropRatio: CGFloat?, completion callersCompletion: @escaping (PhotoLibraryItem?) -> ()) {
        func completion(_ mediaPickerItem: PhotoLibraryItem?) {
            dispatch_to_main_queue {
                callersCompletion(mediaPickerItem)
            }
        }
        
        guard let output = output, let flashOn = flashOn else {
            return completion(nil)
        }
        
        let setting = AVCapturePhotoSettings()
        setting.livePhotoVideoCodecType = .jpeg
        
        if flashOn {
            setting.flashMode = .on
        }
        output.capturePhoto(with: setting, delegate: self)
        
        completionHandler = { [weak self] in
            
            guard let dataImage = self?.photoResult?.cgImageRepresentation()?.takeUnretainedValue() else {
                return completion(nil)
            }
            
            var ciImage = CIImage(cgImage: dataImage)
        
            switch self?.orientationPic {
                case .landscapeRight:
                    ciImage = ciImage.oriented(forExifOrientation: 1)
                case .landscapeLeft:
                    ciImage = ciImage.oriented(forExifOrientation: 3)
                default:
                    ciImage = ciImage.oriented(forExifOrientation: 6)
            }
            
            let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent)
                
            DispatchQueue.global(qos: .userInitiated).async {
                
                guard let cgImage = cgImage,
                      var imageData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 1) else { return completion(nil) }
                
                if let cropRatio = cropRatio {
                    imageData = self?.dataForImage(croppedTo: cropRatio, uncroppedImageData: imageData) ?? imageData
                }
                
                PHPhotoLibrary.requestReadWriteAuthorization { status in
                    guard status == .authorized else {
                        return completion(nil)
                    }
                        
                    var placeholderForCreatedAsset: PHObjectPlaceholder?
                        
                    PHPhotoLibrary.shared().performChanges({
                            
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: imageData, options: nil)
                            
                        placeholderForCreatedAsset = creationRequest.placeholderForCreatedAsset
                            
                    }, completionHandler: { isSuccessful, error in
                        guard isSuccessful, let localIdentifier = placeholderForCreatedAsset?.localIdentifier else {
                            return completion(nil)
                        }
                            
                        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                            
                        completion(fetchResult.lastObject.flatMap { asset in
                            PhotoLibraryItem(image: PHAssetImageSource(asset: asset))
                        })
                    })
                }
            }
        }
    }
    
    private func dataForImage(croppedTo cropRatio: CGFloat, uncroppedImageData: Data) -> Data {
                
        guard let uiImage = UIImage(data: uncroppedImageData), let cgImage = uiImage.cgImage else {
            return uncroppedImageData
        }
        
        let sourceHeight = CGFloat(cgImage.width)
        let targetWidth = CGFloat(cgImage.height)
        let targetHeight = targetWidth / cropRatio
        
        let cropRect = CGRect(
            x: (sourceHeight - targetHeight) / 2,
            y: 0,
            width: targetHeight,
            height: targetWidth
        )
        
        if targetHeight < sourceHeight,
            let croppedImage = cgImage.cropping(to: cropRect),
            let croppedImageData = UIImage(cgImage: croppedImage, scale: uiImage.scale, orientation: .right).jpegData(compressionQuality: 1)
        {
            return croppedImageData
        } else {
            return uncroppedImageData
        }
    }

    private let captureSessionSetupQueue = DispatchQueue(label: "com.CityPower.CameraServiceImpl.captureSessionSetupQueue")
    
    private static func configureCamera(_ camera: AVCaptureDevice?) throws {
        try camera?.lockForConfiguration()
        camera?.isSubjectAreaChangeMonitoringEnabled = true
        camera?.unlockForConfiguration()
    }
    
    private func outputOrientationForCamera(_ camera: AVCaptureDevice?) -> ExifOrientation {
        if camera == frontCamera {
            return .leftMirrored
        } else {
            return .left
        }
    }
    
    private func camera(for cameraType: CameraType) -> AVCaptureDevice? {
        switch cameraType {
        case .back:
            return backCamera
        case .front:
            return frontCamera
        }
    }
    
    private func addCoreMotion() {

        guard let motionManager = motionManager, let operationQueue = OperationQueue.current else { return }
                
        motionManager.gyroUpdateInterval = 0.5
        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: operationQueue, withHandler: { [weak self] (acceleroMeterData, error) -> Void in
            
            if let acceleroMeterData = acceleroMeterData?.acceleration, error == nil {

                var orientationNew = UIInterfaceOrientation(rawValue: 0)!

                if acceleroMeterData.x >= 0.75 {
                    orientationNew = .landscapeLeft
                }
                else if acceleroMeterData.x <= -(0.75) {
                    orientationNew = .landscapeRight
                }
                else if acceleroMeterData.y <= -(0.75) {
                    orientationNew = .portrait
                }
                else if acceleroMeterData.y >= 0.75 {
                    orientationNew = .portraitUpsideDown
                }

                if orientationNew != .unknown {
                    self?.orientationPic = orientationNew
                }
            }
        })
    }
    
}

