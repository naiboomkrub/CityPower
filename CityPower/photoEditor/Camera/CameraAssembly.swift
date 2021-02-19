//
//  CameraAssembly.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 24/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


public enum CameraType {
    case back
    case front
}

protocol CameraAssembly: class {
    func module(initialActiveCameraType: CameraType) -> (UIView, CameraModuleInput)
}

protocol CameraAssemblyFactory {
    func cameraAssembly() -> CameraAssembly
}

extension CameraAssembly {
    func module(initialActiveCameraType: CameraType) -> (UIView, CameraModuleInput) {
        return module(initialActiveCameraType: initialActiveCameraType)
    }
}


final class CameraAssemblyImpl: BasePhotoEditorAssembly, CameraAssembly {
    
    
    func module(initialActiveCameraType: CameraType) -> (UIView, CameraModuleInput) {

        let cameraService = serviceFactory.cameraService(initialActiveCameraType: initialActiveCameraType)
        
        let locationProvider = serviceFactory.locationProvider()
        
        let interactor = CameraInteractorImpl(
            cameraService: cameraService,
            imageMetadataWritingService: serviceFactory.imageMetadataWritingService(),
            locationProvider: locationProvider
        )
        
        let presenter = CameraPresenter(
            interactor: interactor
        )
        
        let view = CameraView()
        view.addDisposable(presenter)
        
        presenter.view = view
        
        return (view, presenter)
    }
}


protocol CameraInteractor: class {
    
    func getOutputParameters(completion: @escaping (CameraOutputParameters?) -> ())
    func setCameraOutputNeeded(_: Bool)
    
    func isFlashAvailable(completion: (Bool) -> ())
    func isFlashEnabled(completion: @escaping (Bool) -> ())
    func setFlashEnabled(_: Bool, completion: ((_ success: Bool) -> ())?)
    
    func canToggleCamera(completion: @escaping (Bool) -> ())
    func toggleCamera(completion: @escaping (_ newOutputOrientation: ExifOrientation) -> ())
    
    func takePhoto(completion: @escaping (PhotoLibraryItem?) -> ())
    
    func setPreviewImagesSizeForNewPhotos(_: CGSize)
    
    func focusCameraOnPoint(_: CGPoint) -> Bool
}

struct CameraOutputParameters {
    let captureSession: AVCaptureSession
    var orientation: ExifOrientation
}


final class CameraInteractorImpl: CameraInteractor {
    
    private let cameraService: CameraService
    private let imageMetadataWritingService: ImageMetadataWritingService
    private let locationProvider: LocationProvider
    private var previewImagesSizeForNewPhotos: CGSize?
    
    init(
        cameraService: CameraService,
        imageMetadataWritingService: ImageMetadataWritingService,
        locationProvider: LocationProvider)
    {
        self.cameraService = cameraService
        self.imageMetadataWritingService = imageMetadataWritingService
        self.locationProvider = locationProvider
    }
    
    func getOutputParameters(completion: @escaping (CameraOutputParameters?) -> ()) {
        cameraService.getCaptureSession { [cameraService] captureSession in
            cameraService.getOutputOrientation { outputOrientation in
                dispatch_to_main_queue {
                    completion(captureSession.flatMap { CameraOutputParameters(
                        captureSession: $0,
                        orientation: outputOrientation)
                    })
                }
            }
        }
    }
    
    func isFlashAvailable(completion: (Bool) -> ()) {
        completion(cameraService.isFlashAvailable)
    }
    
    func isFlashEnabled(completion: @escaping (Bool) -> ()) {
        completion(cameraService.isFlashEnabled)
    }
    
    func setFlashEnabled(_ enabled: Bool, completion: ((_ success: Bool) -> ())?) {
        let success = cameraService.setFlashEnabled(enabled)
        completion?(success)
    }
    
    func canToggleCamera(completion: @escaping (Bool) -> ()) {
        cameraService.canToggleCamera(completion: completion)
    }
    
    func toggleCamera(completion: @escaping (_ newOutputOrientation: ExifOrientation) -> ()) {
        cameraService.toggleCamera(completion: completion)
    }
    
    func takePhoto(completion: @escaping (PhotoLibraryItem?) -> ()) {
        
//        cameraService.takePhoto { [weak self] photo in
//            guard let imageSource = photo.flatMap({ LocalImageSource(path: $0.path) }) else {
//                return completion(nil)
//            }
//
//            if let previewSize = self?.previewImagesSizeForNewPhotos {
//
//                let previewOptions = ImageRequestOptions(size: .fillSize(previewSize), deliveryMode: .best)
//
//                imageSource.requestImage(options: previewOptions) { (result: ImageRequestResult<CGImageWrapper>) in
//                    let imageSourceWithPreview = photo.flatMap {
//                        LocalImageSource(path: $0.path, previewImage: result.image?.image)
//                    }
//                    completion(imageSourceWithPreview.flatMap { MediaPickerItem(image: $0, source: .camera) })
//                }
//
//            } else {
//                completion(MediaPickerItem(image: imageSource, source: .camera))
//            }
//
//            self?.addGpsDataToExif(of: imageSource)
//        }
        
        cameraService.takePhotoToPhotoLibrary(croppedToRatio: nil, completion: completion)
            
    }
    
    private func addGpsDataToExif(of imageSource: LocalImageSource) {
        locationProvider.location { [imageMetadataWritingService] location in
            guard let location = location else { return }
            imageMetadataWritingService.writeGpsData(from: location, to: imageSource, completion: nil)
        }
    }
    
    func setPreviewImagesSizeForNewPhotos(_ size: CGSize) {
        previewImagesSizeForNewPhotos = CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    func setCameraOutputNeeded(_ isCameraOutputNeeded: Bool) {
        cameraService.setCaptureSessionRunning(isCameraOutputNeeded)
    }
    
    func focusCameraOnPoint(_ focusPoint: CGPoint) -> Bool {
        return cameraService.focusOnPoint(focusPoint)
    }
}


protocol CameraModuleInput: class {
    
    func getOutputParameters(completion: @escaping (CameraOutputParameters?) -> ())
    func setCameraOutputNeeded(_: Bool)
    
    func isFlashAvailable(completion: @escaping (Bool) -> ())
    func isFlashEnabled(completion: @escaping (Bool) -> ())
    func setFlashEnabled(_: Bool, completion: ((_ success: Bool) -> ())?)
    
    func canToggleCamera(completion: @escaping (Bool) -> ())
    func toggleCamera(completion: @escaping (_ newOutputOrientation: ExifOrientation) -> ())
    
    func takePhoto(completion: @escaping (PhotoLibraryItem?) -> ())
    
    func setPreviewImagesSizeForNewPhotos(_: CGSize)
    
    func setTitle(_: String)
    func setSubtitle(_: String)
    func setCameraHintVisible(_: Bool)
    func setCameraHint(text: String)
}


final class CameraPresenter: CameraModuleInput {
    
    private let interactor: CameraInteractor
    
    weak var view: CameraViewInput? {
        didSet {
            setUpView()
        }
    }
    
    init(interactor: CameraInteractor) {
        self.interactor = interactor
    }
        
    func getOutputParameters(completion: @escaping (CameraOutputParameters?) -> ()) {
        interactor.getOutputParameters(completion: completion)
    }
    
    func setCameraOutputNeeded(_ isCameraOutputNeeded: Bool) {
        interactor.setCameraOutputNeeded(isCameraOutputNeeded)
    }
    
    func isFlashAvailable(completion: @escaping (Bool) -> ()) {
        interactor.isFlashAvailable(completion: completion)
    }
    
    func isFlashEnabled(completion: @escaping (Bool) -> ()) {
        interactor.isFlashEnabled(completion: completion)
    }
    
    func setFlashEnabled(_ enabled: Bool, completion: ((_ success: Bool) -> ())?) {
        interactor.setFlashEnabled(enabled, completion: completion)
    }
    
    func canToggleCamera(completion: @escaping (Bool) -> ()) {
        interactor.canToggleCamera(completion: completion)
    }
    
    func toggleCamera(completion: @escaping (_ newOutputOrientation: ExifOrientation) -> ()) {
        interactor.toggleCamera { [weak self] newOutputOrientation in
            self?.view?.setOutputOrientation(newOutputOrientation)
            completion(newOutputOrientation)
        }
    }
    
    func takePhoto(completion: @escaping (PhotoLibraryItem?) -> ()) {
        interactor.takePhoto(completion: completion)
    }
    
    func setPreviewImagesSizeForNewPhotos(_ size: CGSize) {
        interactor.setPreviewImagesSizeForNewPhotos(size)
    }
    
    
    func setTitle(_ title: String) {
        view?.setTitle(title)
    }
    
    func setSubtitle(_ subtitle: String) {
        view?.setSubtitle(subtitle)
    }
    
    func setCameraHintVisible(_ visible: Bool) {
        view?.setCameraHintVisible(visible)
    }
    func setCameraHint(text: String) {
        view?.setCameraHint(text: text)
    }
    
    private func setUpView() {
        
        view?.onAccessDeniedButtonTap = {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        
        interactor.getOutputParameters { [weak self] parameters in
            if let parameters = parameters {
                self?.view?.setOutputParameters(parameters)
                
            } else {
                self?.view?.setAccessDeniedViewVisible(true)
            }
        }
        
        view?.onFocusTap = { [weak self] focusPoint, touchPoint in
            if self?.interactor.focusCameraOnPoint(focusPoint) == true {
                self?.view?.displayFocus(onPoint: touchPoint)
            }
        }

    }
}
