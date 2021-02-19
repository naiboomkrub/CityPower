//
//  MediaPickerViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit

enum MediaPickerViewMode {
    case camera
    case photoPreview(MediaPickerItem)
}

enum MediaPickerTitleStyle {
    case dark
    case light
}

enum MediaPickerAutocorrectionStatus {
    case original
    case corrected
}

protocol MediaPickerViewInput: class {
    
    func setMode(_: MediaPickerViewMode)
    
    func setCameraOutputParameters(_: CameraOutputParameters)
    func setCameraOutputOrientation(_: ExifOrientation)
    
    func setPhotoTitle(_: String)
    func setPhotoTitleAlpha(_: CGFloat)
    func setContinueButtonEnabled(_: Bool)
    
    func setLatestLibraryPhoto(_: ImageSource?)
    
    func setFlashButtonVisible(_: Bool)
    func setFlashButtonOn(_: Bool)
    func animateFlash()
    
    func addItems(_: [MediaPickerItem], animated: Bool, completion: @escaping () -> ())
    func updateItem(_: MediaPickerItem)
    func removeItem(_: MediaPickerItem)
    func selectItem(_: MediaPickerItem)
    func moveItem(from sourceIndex: Int, to destinationIndex: Int)
    func scrollToItemThumbnail(_: MediaPickerItem, animated: Bool)
    
    func selectCamera()
    func scrollToCameraThumbnail(animated: Bool)
    
    func setCameraControlsEnabled(_: Bool)
    func setCameraButtonVisible(_: Bool)
    func setShutterButtonEnabled(_: Bool)
    func setPhotoLibraryButtonEnabled(_: Bool)
    
    var onCloseButtonTap: (() -> ())? { get set }
    var onContinueButtonTap: (() -> ())? { get set }
    
    var onCameraToggleButtonTap: (() -> ())? { get set }
    func setCameraToggleButtonVisible(_: Bool)
    
    func setContinueButtonVisible(_: Bool)
    
    func setShowPreview(_: Bool)
    
    func showInfoMessage(_: String, timeout: TimeInterval)
    
    var onItemSelect: ((MediaPickerItem) -> ())? { get set }
    var onItemMove: ((_ sourceIndex: Int, _ destinationIndex: Int) -> ())? { get set }
    
    var onPhotoLibraryButtonTap: (() -> ())? { get set }
    var onShutterButtonTap: (() -> ())? { get set }
    var onFlashToggle: ((Bool) -> ())? { get set }
    
    var onRemoveButtonTap: (() -> ())? { get set }
    var onCropButtonTap: (() -> ())? { get set }
    var onCameraThumbnailTap: (() -> ())? { get set }
    
    var onSwipeToItem: ((MediaPickerItem) -> ())? { get set }
    var onSwipeToCamera: (() -> ())? { get set }
    var onSwipeToCameraProgressChange: ((CGFloat) -> ())? { get set }
    
    var onViewDidLoad: (() -> ())? { get set }
    var onViewDidAppear: ((_ animated: Bool) -> ())? { get set }
    var onViewWillAppear: ((_ animated: Bool) -> ())? { get set }
    var onViewDidDisappear: ((_ animated: Bool) -> ())? { get set }
    
    var onPreviewSizeDetermined: ((_ previewSize: CGSize) -> ())? { get set }
}


final class MediaPickerViewController: PhotoEditorViewController, MediaPickerViewInput {
    
    private let mediaPickerView = MediaPickerView()
    private var layoutSubviewsPromise = Promise<Void>()
    private var isAnimatingTransition: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        view.addSubview(mediaPickerView)
        onViewDidLoad?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        onViewWillAppear?(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            mediaPickerView.alpha = 0
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDidDisappear?(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if mediaPickerView.alpha == 0 {
            DispatchQueue.main.async {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.mediaPickerView.alpha = 1
                })
            }
        }

        onViewDidAppear?(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isAnimatingTransition {
            layoutMediaPickerView(bounds: view.bounds)
        }
        
        onPreviewSizeDetermined?(mediaPickerView.previewSize)
        layoutSubviewsPromise.fulfill(())
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        isAnimatingTransition = true
        
        coordinator.animate(alongsideTransition: { [weak self] context in
            self?.layoutMediaPickerView(bounds: context.containerView.bounds)
        },
        completion: { [weak self] _ in
            self?.isAnimatingTransition = false
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return super.preferredInterfaceOrientationForPresentation
        } else {
            return .portrait
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - MediaPickerViewInput
    
    var onShutterButtonTap: (() -> ())? {
        get { return mediaPickerView.onShutterButtonTap }
        set { mediaPickerView.onShutterButtonTap = newValue }
    }
    
    var onPhotoLibraryButtonTap: (() -> ())? {
        get { return mediaPickerView.onPhotoLibraryButtonTap }
        set { mediaPickerView.onPhotoLibraryButtonTap = newValue }
    }
    
    var onFlashToggle: ((Bool) -> ())? {
        get { return mediaPickerView.onFlashToggle }
        set { mediaPickerView.onFlashToggle = newValue }
    }
    
    var onItemSelect: ((MediaPickerItem) -> ())? {
        get { return mediaPickerView.onItemSelect }
        set { mediaPickerView.onItemSelect = newValue }
    }
    
    var onItemMove: ((Int, Int) -> ())? {
        get { return mediaPickerView.onItemMove }
        set { mediaPickerView.onItemMove = newValue }
    }
    
    var onRemoveButtonTap: (() -> ())? {
        get { return mediaPickerView.onRemoveButtonTap }
        set { mediaPickerView.onRemoveButtonTap = newValue }
    }
    
    var onCropButtonTap: (() -> ())? {
        get { return mediaPickerView.onCropButtonTap }
        set { mediaPickerView.onCropButtonTap = newValue }
    }
    
    var onCameraThumbnailTap: (() -> ())? {
        get { return mediaPickerView.onCameraThumbnailTap }
        set { mediaPickerView.onCameraThumbnailTap = newValue }
    }
    
    var onSwipeToItem: ((MediaPickerItem) -> ())? {
        get { return mediaPickerView.onSwipeToItem }
        set { mediaPickerView.onSwipeToItem = newValue }
    }
    
    var onSwipeToCamera: (() -> ())? {
        get { return mediaPickerView.onSwipeToCamera }
        set { mediaPickerView.onSwipeToCamera = newValue }
    }
    
    var onSwipeToCameraProgressChange: ((CGFloat) -> ())? {
        get { return mediaPickerView.onSwipeToCameraProgressChange }
        set { mediaPickerView.onSwipeToCameraProgressChange = newValue }
    }
    
    var onViewDidLoad: (() -> ())?
    var onViewWillAppear: ((_ animated: Bool) -> ())?
    var onViewDidAppear: ((_ animated: Bool) -> ())?
    var onViewDidDisappear: ((_ animated: Bool) -> ())?
    var onPreviewSizeDetermined: ((_ previewSize: CGSize) -> ())?
    
    func setMode(_ mode: MediaPickerViewMode) {

        DispatchQueue.main.async {
            self.mediaPickerView.setMode(mode)
        }
    }
    
    func setCameraOutputParameters(_ parameters: CameraOutputParameters) {
        mediaPickerView.setCameraOutputParameters(parameters)
    }
    
    func setCameraOutputOrientation(_ orientation: ExifOrientation) {
        mediaPickerView.setCameraOutputOrientation(orientation)
    }
    
    func setPhotoTitle(_ title: String) {
        mediaPickerView.setPhotoTitle(title)
    }
    


    func setPhotoTitleAlpha(_ alpha: CGFloat) {
        mediaPickerView.setPhotoTitleAlpha(alpha)
    }
        
    func setContinueButtonEnabled(_ enabled: Bool) {
        mediaPickerView.setContinueButtonEnabled(enabled)
    }
    
    func setHapticFeedbackEnabled(_ enabled: Bool) {
        mediaPickerView.setHapticFeedbackEnabled(enabled)
    }
    
    func setContinueButtonVisible(_ visible: Bool) {
        mediaPickerView.setContinueButtonVisible(visible)
    }
    
    func setLatestLibraryPhoto(_ image: ImageSource?) {
        mediaPickerView.setLatestPhotoLibraryItemImage(image)
    }
    
    func setFlashButtonVisible(_ visible: Bool) {
        mediaPickerView.setFlashButtonVisible(visible)
    }
    
    func setFlashButtonOn(_ isOn: Bool) {
        mediaPickerView.setFlashButtonOn(isOn)
    }
    
    func animateFlash() {
        mediaPickerView.animateFlash()
    }
    
    var onCloseButtonTap: (() -> ())? {
        get { return mediaPickerView.onCloseButtonTap }
        set { mediaPickerView.onCloseButtonTap = newValue }
    }
    
    var onContinueButtonTap: (() -> ())? {
        get { return mediaPickerView.onContinueButtonTap }
        set { mediaPickerView.onContinueButtonTap = newValue }
    }
    
    var onCameraToggleButtonTap: (() -> ())? {
        get { return mediaPickerView.onCameraToggleButtonTap }
        set { mediaPickerView.onCameraToggleButtonTap = newValue }
    }
    
    func setCameraToggleButtonVisible(_ visible: Bool) {
        mediaPickerView.setCameraToggleButtonVisible(visible)
    }
    
    func addItems(_ items: [MediaPickerItem], animated: Bool, completion: @escaping () -> ()) {
        mediaPickerView.addItems(items, animated: animated, completion: completion)
    }
    
    func updateItem(_ item: MediaPickerItem) {
        mediaPickerView.updateItem(item)
    }
    
    func removeItem(_ item: MediaPickerItem) {
        mediaPickerView.removeItem(item)
    }
    
    func selectItem(_ item: MediaPickerItem) {
        mediaPickerView.selectItem(item)
        onItemSelect?(item)
    }
    
    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        mediaPickerView.moveItem(from: sourceIndex, to: destinationIndex)
    }
    
    func scrollToItemThumbnail(_ item: MediaPickerItem, animated: Bool) {
        layoutSubviewsPromise.onFulfill { [weak self] _ in
            self?.mediaPickerView.scrollToItemThumbnail(item, animated: animated)
        }
    }
    
    func selectCamera() {
        mediaPickerView.selectCamera()
        onCameraThumbnailTap?()
    }
    
    func scrollToCameraThumbnail(animated: Bool) {
        layoutSubviewsPromise.onFulfill { [weak self] _ in
            self?.mediaPickerView.scrollToCameraThumbnail(animated: animated)
        }
    }
    
    func setCameraControlsEnabled(_ enabled: Bool) {
        mediaPickerView.setCameraControlsEnabled(enabled)
    }
    
    func setCameraButtonVisible(_ visible: Bool) {
        mediaPickerView.setCameraButtonVisible(visible)
    }
    
    func setShutterButtonEnabled(_ enabled: Bool) {
        mediaPickerView.setShutterButtonEnabled(enabled)
    }
    
    func setPhotoLibraryButtonEnabled(_ enabled: Bool) {
        mediaPickerView.setPhotoLibraryButtonEnabled(enabled)
    }
    
    func showInfoMessage(_ message: String, timeout: TimeInterval) {
        mediaPickerView.showInfoMessage(message, timeout: timeout)
    }
    
    func setCameraView(_ view: UIView) {
        mediaPickerView.setCameraView(view)
    }
    
    func setShowsCropButton(_ showsCropButton: Bool) {
        mediaPickerView.setShowsCropButton(showsCropButton)
    }
    
    func setShowPreview(_ showPreview: Bool) {
        mediaPickerView.setShowsPreview(showPreview)
    }
    
    
    func layoutMediaPickerView(bounds: CGRect) {
        mediaPickerView.frame = bounds
    }
}
