//
//  MediaPickerView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


final class MediaPickerView: UIView {
    
    private let notchMaskingView = UIView()
    private let cameraControlsView = CameraControlsView()
    private let photoControlsView = PhotoControlsView()
    
    private let closeButton = UIButton()
    private let topRightContinueButton = UIButton()
    private let photoTitleLabel = UILabel()
    private let flashView = UIView()
    
    private let thumbnailRibbonView: ThumbnailsView
    private let photoPreviewView: PhotoPreviewView
    
    private let fakeNavigationBarMinimumYOffset = CGFloat(20)
    private let fakeNavigationBarContentTopInset = CGFloat(8)
    
    private var mode = MediaPickerViewMode.camera
    private let infoMessageDisplayer = InfoMessageDisplayer()
        
    private var showsPreview: Bool = true {
        didSet {
            thumbnailRibbonView.isHidden = !showsPreview
        }
    }
    
    override init(frame: CGRect) {
        
        thumbnailRibbonView = ThumbnailsView()
        photoPreviewView = PhotoPreviewView()
        
        super.init(frame: .zero)
                        
        backgroundColor = .white
        notchMaskingView.backgroundColor = .black
        flashView.backgroundColor = .white
        flashView.alpha = 0
        
        setUpButtons()
        setUpThumbnailRibbonView()
        
        photoTitleLabel.textColor = .black
        photoTitleLabel.alpha = 0
        
        addSubview(notchMaskingView)
        addSubview(photoPreviewView)
        addSubview(flashView)
        addSubview(cameraControlsView)
        addSubview(photoControlsView)
        addSubview(thumbnailRibbonView)
        addSubview(closeButton)
        addSubview(photoTitleLabel)
        addSubview(topRightContinueButton)
        
        setMode(.camera)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cameraAspectRatio = CGFloat(4) / 3
        
        layOutNotchMaskingView()
        layOutFakeNavigationBarButtons()
        
        let controlsIdealFrame = CGRect(x: bounds.origin.x, y: bounds.maxY - safeAreaInsets.bottom - 93, width: bounds.width, height: 93)
        let previewIdealHeight = bounds.width * cameraAspectRatio
        let previewIdealBottom = notchMaskingView.bounds.maxY + previewIdealHeight
        let thumbnailRibbonUnderPreviewHeight = max(controlsIdealFrame.origin.y - previewIdealBottom, 120)

        layOutMainAreaWithThumbnailRibbonUnderPreview(controlsFrame: controlsIdealFrame, thumbnailRibbonHeight: thumbnailRibbonUnderPreviewHeight)

        flashView.frame = photoPreviewView.frame
    }
    
    private func setUpButtons() {

        closeButton.layer.cornerRadius = 19
        closeButton.layer.masksToBounds = true
        closeButton.frame.size = CGSize(width: 44, height: 44)
        closeButton.setImage(UIImage(named:"bt-close"), for: .normal)
        closeButton.addTarget(self, action: #selector(onCloseButtonTap(_:)), for: .touchUpInside)
        
        topRightContinueButton.setTitleColor(.blueCity, for: .normal)
        topRightContinueButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
        topRightContinueButton.setTitle("Done", for: .normal)
        topRightContinueButton.frame.size = CGSize(width: 80, height: 44)
        topRightContinueButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        topRightContinueButton.addTarget(self, action: #selector(onContinueButtonTap(_:)), for: .touchUpInside)
    }
    
    private func layOutNotchMaskingView() {
        let height = safeAreaInsets.top
        notchMaskingView.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: height)
    }
    
    private func layOutFakeNavigationBarButtons() {
        
        closeButton.frame.origin = CGPoint(
            x: bounds.origin.x + 8,
            y: max(notchMaskingView.bounds.maxY, fakeNavigationBarMinimumYOffset) + fakeNavigationBarContentTopInset)
        
        topRightContinueButton.frame.origin = CGPoint(
            x: bounds.maxX - 8 - topRightContinueButton.bounds.width,
            y: max(notchMaskingView.bounds.maxY, fakeNavigationBarMinimumYOffset) + fakeNavigationBarContentTopInset)
    }
        
    
    private func layOutMainAreaWithThumbnailRibbonUnderPreview(controlsFrame: CGRect, thumbnailRibbonHeight: CGFloat) {
        
        cameraControlsView.frame = controlsFrame
        photoControlsView.frame = controlsFrame

        thumbnailRibbonView.backgroundColor = .white
        thumbnailRibbonView.contentInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        thumbnailRibbonView.frame = CGRect(x: bounds.origin.x, y: cameraControlsView.frame.origin.y - thumbnailRibbonHeight, width: bounds.width, height: thumbnailRibbonHeight)
        photoPreviewView.frame = CGRect(x: bounds.origin.x, y: closeButton.frame.maxY, width: bounds.width, height: thumbnailRibbonView.frame.origin.y - closeButton.frame.maxY)
    }
    
    private func layOutPhotoTitleLabel() {
        photoTitleLabel.sizeToFit()
        photoTitleLabel.frame.origin.x = ceil(bounds.midX - photoTitleLabel.bounds.width / 2)
        photoTitleLabel.frame.origin.y = max(notchMaskingView.bounds.maxY, fakeNavigationBarMinimumYOffset) + fakeNavigationBarContentTopInset + photoTitleLabel.bounds.height / 2
    }
    
    
    // MARK: - MediaPickerView
    var onShutterButtonTap: (() -> ())? {
        get { return cameraControlsView.onShutterButtonTap }
        set { cameraControlsView.onShutterButtonTap = newValue }
    }
    
    var onPhotoLibraryButtonTap: (() -> ())? {
        get { return cameraControlsView.onPhotoLibraryButtonTap }
        set { cameraControlsView.onPhotoLibraryButtonTap = newValue }
    }
    
    var onFlashToggle: ((Bool) -> ())? {
        get { return cameraControlsView.onFlashToggle }
        set { cameraControlsView.onFlashToggle = newValue }
    }
    
    var onItemSelect: ((MediaPickerItem) -> ())?
    
    var onRemoveButtonTap: (() -> ())? {
        get { return photoControlsView.onRemoveButtonTap }
        set { photoControlsView.onRemoveButtonTap = newValue }
    }
        
    var onCropButtonTap: (() -> ())? {
        get { return photoControlsView.onCropButtonTap }
        set { photoControlsView.onCropButtonTap = newValue }
    }
    
    var onCameraThumbnailTap: (() -> ())? {
        get { return photoControlsView.onCameraButtonTap }
        set { photoControlsView.onCameraButtonTap = newValue }
    }
    
    var onItemMove: ((Int, Int) -> ())?
    
    var onSwipeToItem: ((MediaPickerItem) -> ())? {
        get { return photoPreviewView.onSwipeToItem }
        set { photoPreviewView.onSwipeToItem = newValue }
    }
    
    var onSwipeToCamera: (() -> ())? {
        get { return photoPreviewView.onSwipeToCamera }
        set { photoPreviewView.onSwipeToCamera = newValue }
    }
    
    var onSwipeToCameraProgressChange: ((CGFloat) -> ())? {
        get { return photoPreviewView.onSwipeToCameraProgressChange }
        set { photoPreviewView.onSwipeToCameraProgressChange = newValue }
    }
    
    var previewSize: CGSize {
        return photoPreviewView.bounds.size
    }
    
    func setMode(_ mode: MediaPickerViewMode) {
        
        switch mode {
        
        case .camera:
            cameraControlsView.isHidden = false
            photoControlsView.isHidden = true
            
            thumbnailRibbonView.selectCameraItem()
            photoPreviewView.scrollToCamera()
        
        case .photoPreview(let photo):
            
            photoPreviewView.scrollToMediaItem(photo)
            
            cameraControlsView.isHidden = true
            photoControlsView.isHidden = false
        }
        
        self.mode = mode
    }
        
    func setCameraControlsEnabled(_ enabled: Bool) {
        cameraControlsView.setCameraControlsEnabled(enabled)
    }
    
    func setCameraButtonVisible(_ visible: Bool) {
        photoPreviewView.setCameraVisible(visible)
        thumbnailRibbonView.setCameraItemVisible(visible)
    }
    
    func setHapticFeedbackEnabled(_ enabled: Bool) {
        photoPreviewView.hapticFeedbackEnabled = enabled
        thumbnailRibbonView.setHapticFeedbackEnabled(enabled)
    }
    
    func setLatestPhotoLibraryItemImage(_ image: ImageSource?) {
        cameraControlsView.setLatestPhotoLibraryItemImage(image)
    }
    
    func setFlashButtonVisible(_ visible: Bool) {
        cameraControlsView.setFlashButtonVisible(visible)
    }
    
    func setFlashButtonOn(_ isOn: Bool) {
        cameraControlsView.setFlashButtonOn(isOn)
    }
    
    func animateFlash() {
        
        flashView.alpha = 1
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.flashView.alpha = 0
            },
            completion: nil
        )
    }
    
    var onCloseButtonTap: (() -> ())?
    
    var onContinueButtonTap: (() -> ())?
    
    var onCameraToggleButtonTap: (() -> ())? {
        get { return cameraControlsView.onCameraToggleButtonTap }
        set { cameraControlsView.onCameraToggleButtonTap = newValue }
    }
    
    func setCameraToggleButtonVisible(_ visible: Bool) {
        cameraControlsView.setCameraToggleButtonVisible(visible)
    }
    
    func setShutterButtonEnabled(_ enabled: Bool) {
        cameraControlsView.setShutterButtonEnabled(enabled)
    }
    
    func setPhotoLibraryButtonEnabled(_ enabled: Bool) {
        cameraControlsView.setPhotoLibraryButtonEnabled(enabled)
    }
    
    func setContinueButtonVisible(_ isVisible: Bool) {
        topRightContinueButton.isHidden = !isVisible
    }
    
    func addItems(_ items: [MediaPickerItem], animated: Bool, completion: @escaping () -> ()) {
        photoPreviewView.addItems(items)
        thumbnailRibbonView.addItems(items, animated: animated, completion: completion)
    }
    
    func updateItem(_ item: MediaPickerItem) {
        photoPreviewView.updateItem(item)
        thumbnailRibbonView.updateItem(item)
    }

    func removeItem(_ item: MediaPickerItem) {
        photoPreviewView.removeItem(item, animated: false)
        thumbnailRibbonView.removeItem(item, animated: true)
    }
    
    func selectItem(_ item: MediaPickerItem) {
        thumbnailRibbonView.selectMediaItem(item)
    }
    
    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        photoPreviewView.moveItem(from: sourceIndex, to: destinationIndex)
    }
    
    func scrollToItemThumbnail(_ item: MediaPickerItem, animated: Bool) {
        thumbnailRibbonView.scrollToItemThumbnail(item, animated: animated)
    }
    
    func selectCamera() {
        thumbnailRibbonView.selectCameraItem()
    }
    
    func scrollToCameraThumbnail(animated: Bool) {
        thumbnailRibbonView.scrollToCameraThumbnail(animated: animated)
    }
    
    func setCameraView(_ view: UIView) {
        photoPreviewView.cameraView = view
    }
    
    func setCameraOutputParameters(_ parameters: CameraOutputParameters) {
        thumbnailRibbonView.setCameraOutputParameters(parameters)
    }
    
    func setCameraOutputOrientation(_ orientation: ExifOrientation) {
        thumbnailRibbonView.setCameraOutputOrientation(orientation)
    }
    
    func setPhotoTitle(_ title: String) {
        photoTitleLabel.text = title
        photoTitleLabel.accessibilityValue = title
        layOutPhotoTitleLabel()
    }
    
    func setPhotoTitleAlpha(_ alpha: CGFloat) {
        photoTitleLabel.alpha = alpha
    }
    
    func setContinueButtonEnabled(_ isEnabled: Bool) {
        topRightContinueButton.isEnabled = isEnabled
    }
    
    func setShowsCropButton(_ showsCropButton: Bool) {
        if showsCropButton {
            photoControlsView.mode.insert(.hasCropButton)
        } else {
            photoControlsView.mode.remove(.hasCropButton)
        }
    }
    
    
    func setShowsPreview(_ showsPreview: Bool) {
        self.showsPreview = showsPreview
    }
    
    func showInfoMessage(_ message: String, timeout: TimeInterval) {
        let viewData = InfoMessageViewData(text: message, timeout: timeout, font: UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!)
        infoMessageDisplayer.display(viewData: viewData, in: photoPreviewView)
    }

    private func setUpThumbnailRibbonView() {
        
        thumbnailRibbonView.onPhotoItemSelect = { [weak self] mediaPickerItem in
            self?.onItemSelect?(mediaPickerItem)
        }
        
        thumbnailRibbonView.onCameraItemSelect = { [weak self] in
            self?.onCameraThumbnailTap?()
        }
        
        thumbnailRibbonView.onItemMove = { [weak self] sourceIndex, destinationIndex in
            self?.onItemMove?(sourceIndex, destinationIndex)
        }
        
        thumbnailRibbonView.onDragStart = { [weak self] in
            self?.isUserInteractionEnabled = false
        }
        
        thumbnailRibbonView.onDragFinish = { [weak self] in
            self?.isUserInteractionEnabled = true
        }
    }
    
    @objc private func onCloseButtonTap(_: UIButton) {
        onCloseButtonTap?()
    }
    
    @objc private func onContinueButtonTap(_: UIButton) {
        onContinueButtonTap?()
    }
}


final class PhotoControlsView: UIView {
    
    struct ModeOptions: OptionSet {
        let rawValue: Int
        
        static let hasRemoveButton  = ModeOptions(rawValue: 1 << 0)
        static let hasCropButton = ModeOptions(rawValue: 1 << 2)
        
        static let allButtons: ModeOptions = [.hasRemoveButton, .hasCropButton]
    }
        
    private let removeButton = UIButton()
    private let cropButton = UIButton()
    private var buttons = [UIButton]()
    
    override init(frame: CGRect) {
        self.mode = [.hasRemoveButton, .hasCropButton]
        
        super.init(frame: frame)
        
        backgroundColor = .white
        
        removeButton.setImage(UIImage(named: "delete"), for: .normal)
        cropButton.setImage(UIImage(named: "crop"), for: .normal)
        
        removeButton.addTarget(self, action: #selector(onRemoveButtonTap(_:)), for: .touchUpInside)
        cropButton.addTarget(self, action: #selector(onCropButtonTap(_:)), for: .touchUpInside)
        
        addSubview(removeButton)
        addSubview(cropButton)
        
        buttons = [removeButton, cropButton]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttons.enumerated().forEach { index, button in
            button.bounds.size = CGSize(width: 44.0, height: 44.0)
            button.center = CGPoint(x: (bounds.width * (2.0 * CGFloat(index) + 1.0)) / 4, y: bounds.height / 2)
        }
    }

    var onRemoveButtonTap: (() -> ())?
    var onCropButtonTap: (() -> ())?
    var onCameraButtonTap: (() -> ())?
    
    var mode: ModeOptions {
        didSet {
            removeButton.isHidden = !mode.contains(.hasRemoveButton)
            cropButton.isHidden = !mode.contains(.hasCropButton)
            setNeedsLayout()
        }
    }
    
    @objc private func onRemoveButtonTap(_: UIButton) {
        onRemoveButtonTap?()
    }
    
    @objc private func onCropButtonTap(_: UIButton) {
        onCropButtonTap?()
    }
}


final class CameraControlsView: UIView {
    
    var onShutterButtonTap: (() -> ())?
    var onPhotoLibraryButtonTap: (() -> ())?
    var onCameraToggleButtonTap: (() -> ())?
    var onFlashToggle: ((Bool) -> ())?
    
    private let photoView = UIImageView()
    private let photoOverlayView = UIView()
    private let shutterButton = UIButton()
    private let cameraToggleButton = UIButton()
    private let flashButton = UIButton()
    
    private let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
    
    private let shutterButtonMinDiameter = CGFloat(44)
    private let shutterButtonMaxDiameter = CGFloat(64)
    
    private let photoViewDiameter = CGFloat(47)
    private var photoViewPlaceholder: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        photoView.backgroundColor = .lightGray
        photoView.contentMode = .scaleAspectFill
        photoView.layer.cornerRadius = photoViewDiameter / 2
        photoView.clipsToBounds = true
        photoView.isUserInteractionEnabled = true
        photoView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(onPhotoViewTap(_:))
        ))
        
        flashButton.setImage(UIImage(named: "light_off"), for: .normal)
        flashButton.setImage(UIImage(named: "light_on"), for: .selected)
        cameraToggleButton.setImage(UIImage(named: "back_front"), for: .normal)
        photoViewPlaceholder = UIImage(named: "gallery-placeholder")
        
        shutterButton.setImage(UIImage(named: "camera"), for: .normal)
        shutterButton.backgroundColor = shutterButton.isEnabled ? UIColor.Gray6: UIColor.lightGray
        shutterButton.layer.borderWidth = 3.0
        shutterButton.layer.borderColor = UIColor.white.cgColor
        
        photoOverlayView.backgroundColor = .black
        photoOverlayView.alpha = 0.04
        photoOverlayView.layer.cornerRadius = photoViewDiameter / 2
        photoOverlayView.clipsToBounds = true
        photoOverlayView.isUserInteractionEnabled = false
        
        shutterButton.clipsToBounds = false
        shutterButton.addTarget(
            self,
            action: #selector(onShutterButtonTouchDown(_:)),
            for: .touchDown
        )
        shutterButton.addTarget(
            self,
            action: #selector(onShutterButtonTouchUp(_:)),
            for: .touchUpInside
        )
        
        flashButton.addTarget(
            self,
            action: #selector(onFlashButtonTap(_:)),
            for: .touchUpInside
        )
        
        cameraToggleButton.addTarget(
            self,
            action: #selector(onCameraToggleButtonTap(_:)),
            for: .touchUpInside
        )
        
        addSubview(photoView)
        addSubview(photoOverlayView)
        addSubview(shutterButton)
        addSubview(flashButton)
        addSubview(cameraToggleButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let contentHeight = bounds.inset(by: insets).size.height
        let shutterButtonDiameter = max(shutterButtonMinDiameter, min(shutterButtonMaxDiameter, contentHeight))
        let shutterButtonSize = CGSize(width: shutterButtonDiameter, height: shutterButtonDiameter)
        let centerY = bounds.midY
        
        shutterButton.frame = CGRect(origin: .zero, size: shutterButtonSize)
        shutterButton.center = CGPoint(x: bounds.midX, y: centerY)
        shutterButton.layer.cornerRadius = shutterButtonDiameter / 2
        
        flashButton.bounds.size = CGSize(width: 44, height: 44)
        flashButton.frame.origin.x = bounds.maxX - flashButton.bounds.width / 2 - 30
        flashButton.center.y = bounds.midY
        
        cameraToggleButton.bounds.size = CGSize(width: 44, height: 44)
        cameraToggleButton.frame.origin.x = flashButton.frame.midX - 80
        cameraToggleButton.center.y = bounds.midY
        
        photoView.bounds.size = CGSize(width: photoViewDiameter, height: photoViewDiameter)
        photoView.frame.origin.x = bounds.origin.x + insets.left
        photoView.center.y = centerY
        
        photoOverlayView.frame = photoView.frame
    }
    
    func setLatestPhotoLibraryItemImage(_ imageSource: ImageSource?) {
        photoView.setImage(
            fromSource: imageSource,
            size: CGSize(width: photoViewDiameter, height: photoViewDiameter),
            placeholder: photoViewPlaceholder,
            placeholderDeferred: false
        )
    }
    
    func setCameraControlsEnabled(_ enabled: Bool) {
        shutterButton.isEnabled = enabled
        cameraToggleButton.isEnabled = enabled
        flashButton.isEnabled = enabled
        
        shutterButton.backgroundColor = shutterButton.isEnabled ? UIColor.Gray6: UIColor.lightGray
    }
    
    func setFlashButtonVisible(_ visible: Bool) {
        flashButton.isHidden = !visible
    }
    
    func setFlashButtonOn(_ isOn: Bool) {
        flashButton.isSelected = isOn
    }
    
    func setCameraToggleButtonVisible(_ visible: Bool) {
        cameraToggleButton.isHidden = !visible
    }
    
    func setShutterButtonEnabled(_ enabled: Bool) {
        shutterButton.isEnabled = enabled
    }
    
    func setPhotoLibraryButtonEnabled(_ enabled: Bool) {
        photoView.isUserInteractionEnabled = enabled
    }
    
    @objc private func onShutterButtonTouchDown(_ button: UIButton) {
        animateShutterButtonToScale(0.85)
    }
    
    @objc private func onShutterButtonTouchUp(_ button: UIButton) {
        animateShutterButtonToScale(1.0)
        onShutterButtonTap?()
    }
    
    @objc private func onPhotoViewTap(_ tapRecognizer: UITapGestureRecognizer) {
        onPhotoLibraryButtonTap?()
    }
    
    @objc private func onFlashButtonTap(_ button: UIButton) {
        button.isSelected = !button.isSelected
        onFlashToggle?(button.isSelected)
    }
    
    @objc private func onCameraToggleButtonTap(_ button: UIButton) {
        button.isUserInteractionEnabled = false
        onCameraToggleButtonTap?()
        button.isUserInteractionEnabled = true
    }
    
    private func animateShutterButtonToScale(_ scale: CGFloat) {
        
        let keyPath = "transform.scale"
        
        let animation =  CABasicAnimation(keyPath: keyPath)
        let layer = shutterButton.layer.presentation() ?? shutterButton.layer
        
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        animation.fromValue = layer.value(forKey: keyPath)
        animation.toValue = scale
        
        shutterButton.layer.add(animation, forKey: keyPath)
    }
}

