//
//  ImageViewExtension.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit

public typealias PlatformImage = UIImage

@objc public protocol Nuke_ImageDisplaying {

    @objc func nuke_display(image: PlatformImage?)

}

public typealias ImageDisplayingView = UIView & Nuke_ImageDisplaying

extension UIImageView: Nuke_ImageDisplaying {

    open func nuke_display(image: UIImage?) {
        self.image = image
    }
}


@discardableResult
public func loadImage(with request: ImageRequestConvertible,
                      options: ImageLoadingOptions = ImageLoadingOptions.shared,
                      into view: ImageDisplayingView,
                      completion: @escaping DataTask.Completion) -> DataTask? {
    loadImage(with: request, options: options, into: view, progress: nil, completion: completion)
}


@discardableResult
public func loadImage(with request: ImageRequestConvertible,
                      options: ImageLoadingOptions = ImageLoadingOptions.shared,
                      into view: ImageDisplayingView,
                      progress: DataTask.ProgressHandler? = nil,
                      completion: DataTask.Completion? = nil) -> DataTask? {
    assert(Thread.isMainThread)
    let controller = ImageViewController.controller(for: view)
    return controller.loadImage(with: request.asImageRequest(), options: options, progress: progress, completion: completion)
}

public func cancelRequest(for view: ImageDisplayingView) {
    assert(Thread.isMainThread)
    ImageViewController.controller(for: view).cancelOutstandingTask()
}

public struct ImageLoadingOptions {

    public static var shared = ImageLoadingOptions()
    public var placeholder: PlatformImage?
    public var failureImage: PlatformImage?

    public var transition: Transition?
    public var failureImageTransition: Transition?
    public var alwaysTransition = false

    public var isPrepareForReuseEnabled = true
    public var isProgressiveRenderingEnabled = true

    public var pipeline: DataPipeLine?
    public var contentModes: ContentModes?

    public struct ContentModes {

        public var success: UIView.ContentMode
        public var failure: UIView.ContentMode
        public var placeholder: UIView.ContentMode

        public init(success: UIView.ContentMode, failure: UIView.ContentMode, placeholder: UIView.ContentMode) {
            self.success = success; self.failure = failure; self.placeholder = placeholder
        }
    }

    public var tintColors: TintColors?
    public struct TintColors {
        /// Tint color to be used for the loaded image.
        public var success: UIColor?
        /// Tint color to be used when displaying a `failureImage`.
        public var failure: UIColor?
        /// Tint color to be used when displaying a `placeholder`.
        public var placeholder: UIColor?

        public init(success: UIColor?, failure: UIColor?, placeholder: UIColor?) {
            self.success = success; self.failure = failure; self.placeholder = placeholder
        }
    }


    public init(placeholder: UIImage? = nil, transition: Transition? = nil, failureImage: UIImage? = nil, failureImageTransition: Transition? = nil, contentModes: ContentModes? = nil, tintColors: TintColors? = nil) {
        self.placeholder = placeholder
        self.transition = transition
        self.failureImage = failureImage
        self.failureImageTransition = failureImageTransition
        self.contentModes = contentModes
        self.tintColors = tintColors
    }

    public struct Transition {
        var style: Style

        enum Style {
            case fadeIn(parameters: Parameters)
            case custom((ImageDisplayingView, UIImage) -> Void)
        }

        struct Parameters {
            let duration: TimeInterval
            let options: UIView.AnimationOptions
        }

        public static func fadeIn(duration: TimeInterval, options: UIView.AnimationOptions = .allowUserInteraction) -> Transition {
            Transition(style: .fadeIn(parameters:  Parameters(duration: duration, options: options)))
        }

        public static func custom(_ closure: @escaping (ImageDisplayingView, UIImage) -> Void) -> Transition {
            Transition(style: .custom(closure))
        }
    }
    
    public init() {}
}


private final class ImageViewController {
    
    private weak var imageView: ImageDisplayingView?
    private var task: DataTask?

    deinit {
        cancelOutstandingTask()
    }

    init(view: ImageDisplayingView) {
        self.imageView = view
    }

    static var controllerAK = "ImageViewController.AssociatedKey"
    static func controller(for view: ImageDisplayingView) -> ImageViewController {
        if let controller = objc_getAssociatedObject(view, &ImageViewController.controllerAK) as? ImageViewController {
            return controller
        }
        let controller = ImageViewController(view: view)
        objc_setAssociatedObject(view, &ImageViewController.controllerAK, controller, .OBJC_ASSOCIATION_RETAIN)
        return controller
    }

    func loadImage(with request: DataRequest,
                   options: ImageLoadingOptions,
                   progress progressHandler: DataTask.ProgressHandler? = nil,
                   completion: DataTask.Completion? = nil) -> DataTask? {
        cancelOutstandingTask()

        guard let imageView = imageView else {
            return nil
        }

        if options.isPrepareForReuseEnabled {
            imageView.layer.removeAllAnimations()
        }

        let pipeline = options.pipeline ?? DataPipeLine.shared

        if let image = pipeline.cachedImage(for: request) {
            let response = ImageResponse(container: image)
            handle(result: .success(response), fromMemCache: true, options: options)
            if !image.isPreview {
                completion?(.success(response))
                return nil
            }
        }

        if var placeholder = options.placeholder {
            if let tintColor = options.tintColors?.placeholder {
                placeholder = placeholder.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = tintColor
            }
            if let contentMode = options.contentModes?.placeholder {
                imageView.contentMode = contentMode
            }
            
            imageView.nuke_display(image: placeholder)
            
        } else if options.isPrepareForReuseEnabled {
            imageView.nuke_display(image: nil)
        }

        task = pipeline.loadImage(with: request, isMainThreadConfined: true, queue: .main, progress: { [weak self] response, completedCount, totalCount in
            if let response = response, options.isProgressiveRenderingEnabled {
                self?.handle(partialImage: response, options: options)
            }
            progressHandler?(response, completedCount, totalCount)
        }, completion: { [weak self] result in
            self?.handle(result: result, fromMemCache: false, options: options)
            completion?(result)
        })
        return task
    }

    func cancelOutstandingTask() {
        task?.cancel()
        task = nil
    }

    
    private func handle(result: Result<ImageResponse, DataPipeLine.Error>, fromMemCache: Bool, options: ImageLoadingOptions) {
        switch result {
        case let .success(response):
            display(response.image, options.transition, options.alwaysTransition, fromMemCache, options.contentModes?.success, options.tintColors?.success)
        case .failure:
            if let failureImage = options.failureImage {
                display(failureImage, options.failureImageTransition, options.alwaysTransition, fromMemCache, options.contentModes?.failure, options.tintColors?.failure)
            }
        }
        self.task = nil
    }

    private func handle(partialImage response: ImageResponse, options: ImageLoadingOptions) {
        display(response.image, options.transition, options.alwaysTransition, false, options.contentModes?.success, options.tintColors?.success)
    }

    private func display(_ image: UIImage, _ transition: ImageLoadingOptions.Transition?, _ alwaysTransition: Bool, _ fromMemCache: Bool, _ newContentMode: UIView.ContentMode?, _ newTintColor: UIColor?) {
        guard let imageView = imageView else {
            return
        }

        var image = image

        if let newTintColor = newTintColor {
            image = image.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = newTintColor
        }

        if !fromMemCache || alwaysTransition, let transition = transition {
            switch transition.style {
            case let .fadeIn(params):
                runFadeInTransition(image: image, params: params, contentMode: newContentMode)
            case let .custom(closure):
                closure(imageView, image)
            }
        } else {
            imageView.nuke_display(image: image)
        }
        if let newContentMode = newContentMode {
            imageView.contentMode = newContentMode
        }
    }

    private lazy var transitionImageView = UIImageView()

    private func runFadeInTransition(image: UIImage, params: ImageLoadingOptions.Transition.Parameters, contentMode: UIView.ContentMode?) {
        guard let imageView = imageView else {
            return
        }

        if let contentMode = contentMode, imageView.contentMode != contentMode, let imageView = imageView as? UIImageView, imageView.image != nil {
            runCrossDissolveWithContentMode(imageView: imageView, image: image, params: params)
        } else {
            runSimpleFadeIn(image: image, params: params)
        }
    }

    private func runSimpleFadeIn(image: UIImage, params: ImageLoadingOptions.Transition.Parameters) {
        guard let imageView = imageView else {
            return
        }

        UIView.transition(
            with: imageView,
            duration: params.duration,
            options: params.options.union(.transitionCrossDissolve),
            animations: {
                imageView.nuke_display(image: image)
            },
            completion: nil
        )
    }

    private func runCrossDissolveWithContentMode(imageView: UIImageView, image: UIImage, params: ImageLoadingOptions.Transition.Parameters) {

        let transitionView = self.transitionImageView


        transitionView.image = imageView.image
        transitionView.contentMode = imageView.contentMode
        imageView.addSubview(transitionView)
        transitionView.frame = imageView.bounds

        transitionView.alpha = 1
        imageView.alpha = 0
        imageView.image = image 
        UIView.animate(
            withDuration: params.duration,
            delay: 0,
            options: params.options,
            animations: {
                transitionView.alpha = 0
                imageView.alpha = 1
            },
            completion: { isCompleted in
                if isCompleted {
                    transitionView.removeFromSuperview()
                }
            }
        )
    }
}

