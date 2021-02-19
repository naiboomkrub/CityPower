//
//  ImageCroppingAssembly.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import UIKit
import CoreGraphics
import Foundation


protocol ImageCroppingAssembly: class {
    func module(
        image: ImageSource,
        canvasSize: CGSize,
        configure: (ImageCroppingModule) -> ())
        -> UIViewController
}


public protocol ImageCroppingModule: class {
    var onDiscard: (() -> ())? { get set }
    var onConfirm: ((ImageSource) -> ())? { get set }
}


protocol ImageCroppingAssemblyFactory: class {
    func imageCroppingAssembly() -> ImageCroppingAssembly
}


public final class ImageCroppingAssemblyImpl: BasePhotoEditorAssembly, ImageCroppingAssembly {
    
    public func module(image: ImageSource, canvasSize: CGSize, configure: (ImageCroppingModule) -> ()) -> UIViewController {
        
        let imageCroppingService = serviceFactory.imageCroppingService(
            image: image,
            canvasSize: canvasSize
        )

        let interactor = ImageCroppingInteractorImpl(
            imageCroppingService: imageCroppingService
        )

        let presenter = ImageCroppingPresenter(
            interactor: interactor
        )
        
        let viewController = ImageCroppingViewController()
        viewController.addDisposable(presenter)
        presenter.view = viewController
        configure(presenter)

        return viewController
    }
}


protocol ImageCroppingInteractor: class {
    
    func canvasSize(completion: @escaping (CGSize) -> ())
    func imageWithParameters(completion: @escaping (ImageCroppingData) -> ())
    func croppedImage(previewImage: CGImage, completion: @escaping (CroppedImageSource) -> ())
    func croppedImageAspectRatio(completion: @escaping (Float) -> ())
    func setCroppingParameters(_: ImageCroppingParameters)
}


final class ImageCroppingInteractorImpl: ImageCroppingInteractor {
    
    private let imageCroppingService: ImageCroppingService
    
    init(imageCroppingService: ImageCroppingService) {
        self.imageCroppingService = imageCroppingService
    }
    
    func canvasSize(completion: @escaping (CGSize) -> ()) {
        imageCroppingService.canvasSize(completion: completion)
    }
    
    func imageWithParameters(completion: @escaping (ImageCroppingData) -> ()) {
        imageCroppingService.imageWithParameters(completion: completion)
    }
    
    func croppedImage(previewImage: CGImage, completion: @escaping (CroppedImageSource) -> ()) {
        imageCroppingService.croppedImage(previewImage: previewImage, completion: completion)
    }
    
    func croppedImageAspectRatio(completion: @escaping (Float) -> ()) {
        imageCroppingService.croppedImageAspectRatio(completion: completion)
    }
    
    func setCroppingParameters(_ parameters: ImageCroppingParameters) {
        imageCroppingService.setCroppingParameters(parameters)
    }
}


struct ImageCroppingParameters: Equatable {
    
    let transform: CGAffineTransform
    let sourceSize: CGSize
    let sourceOrientation: ExifOrientation
    let outputWidth: CGFloat
    let cropSize: CGSize
    let imageViewSize: CGSize
    
    let contentOffsetCenter: CGPoint
    let turnAngle: CGFloat
    let tiltAngle: CGFloat
    let zoomScale: CGFloat
    let manuallyZoomed: Bool
    
    static func ==(parameters1: ImageCroppingParameters, parameters2: ImageCroppingParameters) -> Bool {
        return parameters1.transform == parameters2.transform &&
               parameters1.sourceSize == parameters2.sourceSize &&
               parameters1.sourceOrientation == parameters2.sourceOrientation &&
               parameters1.outputWidth == parameters2.outputWidth &&
               parameters1.cropSize == parameters2.cropSize &&
               parameters1.imageViewSize == parameters2.imageViewSize &&
               parameters1.contentOffsetCenter == parameters2.contentOffsetCenter &&
               parameters1.turnAngle == parameters2.turnAngle &&
               parameters1.tiltAngle == parameters2.tiltAngle &&
               parameters1.zoomScale == parameters2.zoomScale &&
               parameters1.manuallyZoomed == parameters2.manuallyZoomed
    }
}


enum AspectRatio {
    
    case portrait_3x4
    case landscape_4x3
    
    static let defaultRatio = AspectRatio.landscape_4x3
    
    func widthToHeightRatio() -> Float {
        switch self {
        case .portrait_3x4:
            return Float(3.0 / 4.0)
        case .landscape_4x3:
            return Float(4.0 / 3.0)
        }
    }
    
    func heightToWidthRatio() -> Float {
        return 1 / widthToHeightRatio()
    }
}


protocol ImageCroppingViewInput: class {
    
    func setImage(_: ImageSource, previewImage: ImageSource?, completion: @escaping () -> ())
    func setImageTiltAngle(_: Float)
    func turnImageCounterclockwise()
    func setCroppingParameters(_: ImageCroppingParameters)
    func setRotationSliderValue(_: Float)
    func setCanvasSize(_: CGSize)
    func setControlsEnabled(_: Bool)
    func setAspectRatio(_: AspectRatio)
    func setAspectRatioButtonTitle(_: String)
    
    func setCancelRotationButtonTitle(_: String)
    func setCancelRotationButtonVisible(_: Bool)
    
    func setGridVisible(_: Bool)
    
    var onDiscardButtonTap: (() -> ())? { get set }
    var onConfirmButtonTap: ((_ previewImage: CGImage?) -> ())? { get set }
    var onAspectRatioButtonTap: (() -> ())? { get set }
    var onRotateButtonTap: (() -> ())? { get set }
    var onGridButtonTap: (() -> ())? { get set }
    var onRotationAngleChange: ((Float) -> ())? { get set }
    var onRotationCancelButtonTap: (() -> ())? { get set }
    var onCroppingParametersChange: ((ImageCroppingParameters) -> ())? { get set }
}


final class ImageCroppingPresenter: ImageCroppingModule {

    
    private var interactor: ImageCroppingInteractor
    
    weak var view: ImageCroppingViewInput? {
        didSet {
            setUpView()
        }
    }

    init(interactor: ImageCroppingInteractor) {
        self.interactor = interactor
    }
    
    var onDiscard: (() -> ())?
    var onConfirm: ((ImageSource) -> ())?
    
    
    private func setUpView() {
        
        view?.setControlsEnabled(false)
        
        setGridVisible(false)
        
        view?.onRotationAngleChange = { [weak self] angle in
            self?.setImageRotation(angle)
        }
        
        view?.onRotateButtonTap = { [weak self] in
            self?.view?.turnImageCounterclockwise()
        }
        
        view?.onRotationCancelButtonTap = { [weak self] in
            self?.view?.setRotationSliderValue(0)
            self?.setImageRotation(0)
        }
        
        view?.onCroppingParametersChange = { [weak self] parameters in
            self?.interactor.setCroppingParameters(parameters)
        }
        
        view?.onDiscardButtonTap = { [weak self] in
            self?.onDiscard?()
        }
        
        view?.onConfirmButtonTap = { [weak self] previewImage in
            if let previewImage = previewImage {
                self?.interactor.croppedImage(previewImage: previewImage) { image in
                    self?.onConfirm?(image)
                }
            } else {
                self?.onDiscard?()
            }
        }
        
        interactor.canvasSize { [weak self] canvasSize in
            self?.view?.setCanvasSize(canvasSize)
        }
        
        interactor.croppedImageAspectRatio { [weak self] aspectRatio in
            
            let isPortrait = aspectRatio < 1
            
            self?.setAspectRatio(isPortrait ? .portrait_3x4 : .landscape_4x3)
            
            self?.interactor.imageWithParameters { data in
                self?.view?.setImage(data.originalImage, previewImage: data.previewImage) {
                    self?.view?.setControlsEnabled(true)
                    
                    if let croppingParameters = data.parameters {
                        
                        self?.view?.setCroppingParameters(croppingParameters)
                        
                        let angleInDegrees = Float(croppingParameters.tiltAngle).radiansToDegrees()
                        self?.view?.setRotationSliderValue(angleInDegrees)
                        self?.adjustCancelRotationButton(forAngle: angleInDegrees)
                    }
                }
            }
        }
    }
    
    private func setImageRotation(_ angle: Float) {
        view?.setImageTiltAngle(angle)
        adjustCancelRotationButton(forAngle: angle)
    }
    
    private func adjustCancelRotationButton(forAngle angle: Float) {
        
        let displayedAngle = Int(round(angle))
        let shouldShowCancelRotationButton = (displayedAngle != 0)
        
        view?.setCancelRotationButtonTitle("\(displayedAngle > 0 ? "+" : "")\(displayedAngle)°")
        view?.setCancelRotationButtonVisible(shouldShowCancelRotationButton)
    }
    
    private func setGridVisible(_ visible: Bool) {

        view?.setGridVisible(visible)
        view?.onGridButtonTap = { [weak self] in
            self?.setGridVisible(!visible)
        }
    }
    
    private func setAspectRatio(_ aspectRatio: AspectRatio) {
        
        view?.setAspectRatio(aspectRatio)
        view?.setAspectRatioButtonTitle(aspectRatioButtonTitle(for: aspectRatio))
        
        view?.onAspectRatioButtonTap = { [weak self] in
            if let nextRatio = self?.aspectRatioAfter(aspectRatio) {
                self?.setAspectRatio(nextRatio)
            }
        }
    }
    
    private func aspectRatioButtonTitle(for aspectRatio: AspectRatio) -> String {
        switch aspectRatio {
        case .portrait_3x4:
            return "3:4"
        case .landscape_4x3:
            return "4:3"
        }
    }
    
    private func aspectRatioAfter(_ aspectRatio: AspectRatio) -> AspectRatio {
        switch aspectRatio {
        case .portrait_3x4:
            return .landscape_4x3
        case .landscape_4x3:
            return .portrait_3x4
        }
    }
}

