//
//  ImageCroppingView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics


final class ImageCroppingView: UIView {
    
    private let splashView = UIImageView()
    private let previewView = CroppingPreviewView()
    private let controlsView = ImageCroppingControlsView()
    private let aspectRatioButton = UIButton()
    private let titleLabel = UILabel()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .blueCity
        clipsToBounds = true
        previewView.backgroundColor = .white
        
        titleLabel.text = "Cropping"
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!
        
        aspectRatioButton.layer.borderColor = UIColor.black.cgColor
        aspectRatioButton.layer.borderWidth = 1
        aspectRatioButton.setTitleColor(.white, for: .normal)
        aspectRatioButton.addTarget(
            self,
            action: #selector(onAspectRatioButtonTap(_:)),
            for: .touchUpInside
        )
        
        controlsView.onConfirmButtonTap = { [weak self] in
            self?.onConfirmButtonTap?(self?.previewView.cropPreviewImage())
        }
        
        splashView.contentMode = .scaleAspectFill
        
        previewView.onPreviewImageWillLoading = { [weak self] in
            self?.splashView.isHidden = false
        }
        
        previewView.onPreviewImageDidLoad = { [weak self] image in
            if self?.splashView.isHidden == false {
                self?.splashView.image = image
            }
        }
        
        previewView.onImageDidLoad = { [weak self] in
            self?.splashView.isHidden = true
            self?.splashView.image = nil
        }

        addSubview(previewView)
        addSubview(splashView)
        addSubview(controlsView)
        addSubview(titleLabel)
        addSubview(aspectRatioButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
    
    
    var onDiscardButtonTap: (() -> ())? {
        get { return controlsView.onDiscardButtonTap }
        set { controlsView.onDiscardButtonTap = newValue }
    }
    
    var onConfirmButtonTap: ((_ previewImage: CGImage?) -> ())?
    
    var onRotationAngleChange: ((Float) -> ())? {
        get { return controlsView.onRotationAngleChange }
        set { controlsView.onRotationAngleChange = newValue }
    }
    
    var onRotateButtonTap: (() -> ())? {
        get { return controlsView.onRotateButtonTap }
        set { controlsView.onRotateButtonTap = newValue }
    }
    
    var onRotationCancelButtonTap: (() -> ())? {
        get { return controlsView.onRotationCancelButtonTap }
        set { controlsView.onRotationCancelButtonTap = newValue }
    }
    
    var onGridButtonTap: (() -> ())? {
        get { return controlsView.onGridButtonTap }
        set { controlsView.onGridButtonTap = newValue }
    }
    
    var onAspectRatioButtonTap: (() -> ())?
    
    var onCroppingParametersChange: ((ImageCroppingParameters) -> ())? {
        get { return previewView.onCroppingParametersChange }
        set { previewView.onCroppingParametersChange = newValue }
    }
    
    func setImage(_ image: ImageSource, previewImage: ImageSource?, completion: (() -> ())?) {
        previewView.setImage(image, previewImage: previewImage, completion: completion)
    }
    
    func setImageTiltAngle(_ angle: Float) {
        previewView.setImageTiltAngle(angle)
    }

    func turnCounterclockwise() {
        previewView.turnCounterclockwise()
    }
    
    func setCroppingParameters(_ parameters: ImageCroppingParameters) {
        previewView.setCroppingParameters(parameters)
    }
    
    func setRotationSliderValue(_ value: Float) {
        controlsView.setRotationSliderValue(value)
    }
    
    func setCanvasSize(_ size: CGSize) {
        previewView.setCanvasSize(size)
    }
    
    func setControlsEnabled(_ enabled: Bool) {
        controlsView.setControlsEnabled(enabled)
        aspectRatioButton.isEnabled = enabled
    }
    
    func setAspectRatio(_ aspectRatio: AspectRatio) {
        
        self.aspectRatio = aspectRatio
        
        aspectRatioButton.frame.size = aspectRatioButtonSize()
        previewView.cropAspectRatio = CGFloat(aspectRatio.widthToHeightRatio())
        layoutSplashView()
    }
    
    func setAspectRatioButtonTitle(_ title: String) {
        aspectRatioButton.setTitle(title, for: .normal)
    }
    
    func setCancelRotationButtonTitle(_ title: String) {
        controlsView.setCancelRotationButtonTitle(title)
    }
    
    func setCancelRotationButtonVisible(_ visible: Bool) {
        controlsView.setCancelRotationButtonVisible(visible)
    }
    
    func setGridVisible(_ visible: Bool) {
        previewView.setGridVisible(visible)
    }
    
    private var aspectRatio: AspectRatio = .portrait_3x4
    
    private func aspectRatioButtonSize() -> CGSize {
        switch aspectRatio {
        case .portrait_3x4:
            return CGSize(width: 34, height: 42)
        case .landscape_4x3:
            return CGSize(width: 42, height: 34)
        }
    }
    
    @objc private func onAspectRatioButtonTap(_ sender: UIButton) {
        onAspectRatioButtonTap?()
    }
    
    private func layoutView() {
        
        var controlsHeight: CGFloat
        var yOri : CGFloat
                
        let previewViewAspectRatio = CGFloat(AspectRatio.portrait_3x4.heightToWidthRatio())
        aspectRatioButton.frame.origin.x = bounds.maxX - 15 - aspectRatioButton.frame.width
        
        titleLabel.sizeToFit()
        titleLabel.frame.origin.x = bounds.width / 2 - titleLabel.frame.width / 2
        titleLabel.frame.origin.y = safeAreaInsets.top + 15
        
        aspectRatioButton.frame.origin.y = titleLabel.frame.origin.y
        
        if safeAreaInsets.top < 5 {
            controlsHeight = CGFloat(140)
            yOri = aspectRatioButton.frame.maxY + 10
        } else {
            controlsHeight = CGFloat(209)
            yOri = bounds.maxY - controlsHeight - bounds.width * previewViewAspectRatio
        }
        
        controlsView.frame = CGRect(x: bounds.origin.x, y: bounds.maxY - controlsHeight, width: bounds.width, height: controlsHeight)
        previewView.frame = CGRect(x: bounds.origin.x, y: yOri, width: bounds.width, height: bounds.width * previewViewAspectRatio)
        
        layoutSplashView()
    }
    
    private func layoutSplashView() {
        
        let height: CGFloat
        
        switch aspectRatio {
        case .portrait_3x4:
            height = bounds.size.width * 4 / 3
        case .landscape_4x3:
            height = bounds.size.width * 3 / 4
        }
        
        let scaleToFit = height > 0 ? min(1, previewView.bounds.height / height) : 0
        
        splashView.frame.size = CGSize(width: bounds.size.width, height: height).scaled(scaleToFit)
        splashView.center = previewView.center
    }
}


final class RightIconButton: UIButton {
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = super.imageRect(forContentRect: contentRect)
        rect.origin.x = contentRect.maxX - self.bounds.width / 4 + 12
        return rect
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = super.titleRect(forContentRect: contentRect)
        rect.origin.x = contentRect.origin.x
        return rect
    }
}


final class ImageCroppingControlsView: UIView {
    
    private let rotationSliderView = RotationSliderView()
    private let rotationButton = UIButton()
    private let rotationCancelButton = RightIconButton()
    private let gridButton = UIButton()
    private let discardButton = UIButton()
    private let confirmButton = UIButton()
    
    init() {
        super.init(frame: .zero)
        
        backgroundColor = .white
        
        rotationButton.setImage(UIImage(named: "rotate"), for: .normal)
        gridButton.setImage(UIImage(named: "grid"), for: .normal)
        discardButton.setImage(UIImage(named: "bounds"), for: .normal)
        confirmButton.setImage(UIImage(named: "check"), for: .normal)
        
        rotationCancelButton.backgroundColor = .blueCity
        rotationCancelButton.setTitleColor(.white, for: .normal)
        rotationCancelButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 12, bottom: 3, right: 12)
        rotationCancelButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        rotationCancelButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)

        rotationCancelButton.titleLabel?.textColor = .white
        rotationCancelButton.titleLabel?.font = UIFont(name: "Baskerville-Bold", size: CGFloat(18))!
        rotationCancelButton.setImage(UIImage(named: "close-small"), for: .normal)
        
        rotationCancelButton.addTarget(self, action: #selector(onRotationCancelButtonTap(_:)), for: .touchUpInside)
        rotationButton.addTarget(self, action: #selector(onRotationButtonTap(_:)), for: .touchUpInside)
        gridButton.addTarget(self, action: #selector(onGridButtonTap(_:)), for: .touchUpInside)
        discardButton.addTarget( self, action: #selector(onDiscardButtonTap(_:)), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(onConfirmButtonTap(_:)), for: .touchUpInside)
        
        addSubview(rotationSliderView)
        addSubview(rotationButton)
        addSubview(gridButton)
        addSubview(rotationCancelButton)
        addSubview(discardButton)
        addSubview(confirmButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        rotationSliderView.frame = CGRect(x: bounds.origin.x + 70, y: 19, width: bounds.width - 140, height: 44)
        
        rotationButton.frame.size = CGSize(width: 44, height: 44)
        rotationButton.center = CGPoint(x: 31, y: rotationSliderView.frame.midY)
        
        gridButton.frame.size = CGSize(width: 44, height: 44)
        gridButton.center = CGPoint(x: bounds.maxX - 31, y: rotationSliderView.frame.midY)
        
        rotationCancelButton.frame.origin.x = center.x - rotationCancelButton.frame.width / 2
        rotationCancelButton.frame.origin.y = rotationSliderView.frame.maxY + 11
        
        discardButton.frame.size = CGSize(width: 44, height: 44)
        discardButton.center = CGPoint(
            x: bounds.origin.x + bounds.size.width * 0.25,
            y: bounds.maxY - safeAreaInsets.bottom - 42
        )
        
        confirmButton.frame.size = CGSize(width: 44, height: 44)
        confirmButton.center = CGPoint(x: bounds.maxX - bounds.width * 0.25, y: discardButton.center.y)
    }
    
    var onDiscardButtonTap: (() -> ())?
    var onConfirmButtonTap: (() -> ())?
    var onRotationCancelButtonTap: (() -> ())?
    var onRotateButtonTap: (() -> ())?
    var onGridButtonTap: (() -> ())?
    
    var onRotationAngleChange: ((Float) -> ())? {
        get { return rotationSliderView.onSliderValueChange }
        set { rotationSliderView.onSliderValueChange = newValue }
    }
    
    func setRotationSliderValue(_ value: Float) {
        rotationSliderView.setValue(value)
    }
    
    func setControlsEnabled(_ enabled: Bool) {
        rotationButton.isEnabled = enabled
        gridButton.isEnabled = enabled
        rotationSliderView.isUserInteractionEnabled = enabled
        rotationCancelButton.isEnabled = enabled
    }
    
    func setCancelRotationButtonTitle(_ title: String) {
        rotationCancelButton.setTitle(title, for: .normal)
        rotationCancelButton.sizeToFit()
        rotationCancelButton.layer.cornerRadius = rotationCancelButton.bounds.height / 2
    }
    
    func setCancelRotationButtonVisible(_ visible: Bool) {
        rotationCancelButton.isHidden = !visible
    }
    
    func setGridButtonSelected(_ selected: Bool) {
        gridButton.isSelected = selected
    }
    
    @objc private func onDiscardButtonTap(_: UIButton) {
        onDiscardButtonTap?()
    }
    
    @objc private func onConfirmButtonTap(_: UIButton) {
        onConfirmButtonTap?()
    }
    
    @objc private func onRotationSliderValueChange(_ sender: UISlider) {
        onRotationAngleChange?(sender.value)
    }
    
    @objc private func onRotationCancelButtonTap(_: UIButton) {
        onRotationCancelButtonTap?()
    }
    
    @objc private func onRotationButtonTap(_: UIButton) {
        onRotateButtonTap?()
    }
    
    @objc private func onGridButtonTap(_: UIButton) {
        onGridButtonTap?()
    }
}


final class CroppingPreviewView: UIView {
    
    private static let greatestFiniteMagnitudeSize = CGSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude
    )

    private var sourceImageMaxSize = CroppingPreviewView.greatestFiniteMagnitudeSize
    private let previewView = PhotoTweakView()
    
    init() {
        super.init(frame: .zero)
        
        clipsToBounds = true
        addSubview(previewView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        previewView.frame = bounds
    }
    
    var cropAspectRatio: CGFloat {
        get { return previewView.cropAspectRatio }
        set { previewView.cropAspectRatio = newValue }
    }
    
    var onCroppingParametersChange: ((ImageCroppingParameters) -> ())? {
        get { return previewView.onCroppingParametersChange }
        set { previewView.onCroppingParametersChange = newValue }
    }
    
    var onPreviewImageWillLoading: (() -> ())?
    var onPreviewImageDidLoad: ((UIImage) -> ())?
    var onImageDidLoad: (() -> ())?
    
    func setImage(_ image: ImageSource, previewImage: ImageSource?, completion: (() -> ())?) {
        
        if let previewImage = previewImage {
            
            let screenSize = UIScreen.main.bounds.size
            
            let previewOptions = ImageRequestOptions(size: .fitSize(screenSize), deliveryMode: .progressive)

            onPreviewImageWillLoading?()
            
            previewImage.requestImage(options: previewOptions) { [weak self] (result: ImageRequestResult<UIImage>) in
                if let image = result.image {
                    self?.onPreviewImageDidLoad?(image)
                }
            }
        }
        
        let imageSizeOption: ImageSizeOption = (sourceImageMaxSize == CroppingPreviewView.greatestFiniteMagnitudeSize)
            ? .fullResolution : .fitSize(sourceImageMaxSize)
        
        let options = ImageRequestOptions(size: imageSizeOption, deliveryMode: .best)
        
        image.requestImage(options: options) { [weak self] (result: ImageRequestResult<UIImage>) in
            if let image = result.image {
                self?.previewView.setImage(image)
                self?.onImageDidLoad?()
            }
            completion?()
        }
    }
    
    func setImageTiltAngle(_ angle: Float) {
        previewView.setTiltAngle(angle.degreesToRadians())
    }
    
    func turnCounterclockwise() {
        previewView.turnCounterclockwise()
    }
    
    func setCroppingParameters(_ parameters: ImageCroppingParameters) {
        previewView.setCroppingParameters(parameters)
    }
    
    func setGridVisible(_ visible: Bool) {
        previewView.setGridVisible(visible)
    }
    
    func setCanvasSize(_ size: CGSize) {
        sourceImageMaxSize = size
    }
    
    func cropPreviewImage() -> CGImage? {
        return previewView.cropPreviewImage()
    }
}


final class RotationSliderView: UIView, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let scaleView = SliderScaleView()
    private let thumbView = UIView()
    private let alphaMaskLayer = CAGradientLayer()
    
    private var minimumValue: Float = -25
    private var maximumValue: Float = 25
    private var currentValue: Float = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        contentMode = .redraw
        
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.delegate = self
        
        thumbView.backgroundColor = .blueCity
        thumbView.layer.cornerRadius = scaleView.divisionWidth / 2
        
        alphaMaskLayer.startPoint = CGPoint(x: 0, y: 0)
        alphaMaskLayer.endPoint = CGPoint(x: 1, y: 0)
        alphaMaskLayer.locations = [0, 0.2, 0.8, 1]
        alphaMaskLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.cgColor,
            UIColor.white.cgColor,
            UIColor.clear.cgColor
        ]
        
        layer.mask = alphaMaskLayer
        
        scrollView.addSubview(scaleView)
        
        addSubview(scrollView)
        addSubview(thumbView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let sideInset = ((bounds.size.width - scaleView.divisionWidth) / 2).truncatingRemainder(dividingBy: scaleView.divisionWidth + scaleView.divisionsSpacing)
        
        scaleView.contentInsets = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
        scaleView.frame = CGRect(origin: .zero, size: scaleView.sizeThatFits(bounds.size))
        
        scrollView.frame = bounds
        scrollView.contentSize = scaleView.frame.size
        
        thumbView.frame.size = CGSize(width: scaleView.divisionWidth, height: scaleView.bounds.height)
        thumbView.center = scrollView.center
        
        alphaMaskLayer.frame = bounds
        adjustScrollViewOffset()
    }
    
    var onSliderValueChange: ((Float) -> ())?
    
    func setValue(_ value: Float) {
        currentValue = max(minimumValue, min(maximumValue, value))
        adjustScrollViewOffset()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        let significantWidth = scrollView.contentSize.width - bounds.size.width
        let percentage = offset / significantWidth
        let value = minimumValue + (maximumValue - minimumValue) * Float(percentage)
        
        onSliderValueChange?(value)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: true)
    }
    
    private func adjustScrollViewOffset() {
        
        let percentage = (currentValue - minimumValue) / (maximumValue - minimumValue)
        scrollView.contentOffset = CGPoint(
            x: CGFloat(percentage) * (scrollView.contentSize.width - bounds.size.width), y: 0)
    }
}

private final class SliderScaleView: UIView {
    
    var contentInsets = UIEdgeInsets.zero
    
    let divisionsSpacing = CGFloat(14)
    let divisionsCount = 51
    let divisionWidth = CGFloat(2)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        var width = CGFloat(divisionsCount) * divisionWidth
        width += CGFloat(divisionsCount - 1) * divisionsSpacing
        width += contentInsets.left + contentInsets.right
        
        return CGSize(width: width, height: size.height)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        for i in 0 ..< divisionsCount {
            
            let rect = CGRect(
                x: bounds.origin.x + contentInsets.left + CGFloat(i) * (divisionWidth + divisionsSpacing),
                y: bounds.origin.y,
                width: divisionWidth,
                height: bounds.size.height
            )
            
            UIColor.Gray3.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: divisionWidth / 2).fill()
        }
    }
}


final class GridView: UIView {
    
    let rowsCount = 3
    let columnsCount = 3
    
    private let shapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.shadowColor = UIColor.black.cgColor
        shapeLayer.shadowOpacity = 0.1
        shapeLayer.shadowOffset = .zero
        shapeLayer.shadowRadius = 2
        
        layer.addSublayer(shapeLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        shapeLayer.frame = bounds
        shapeLayer.path = path(forRect: shapeLayer.bounds).cgPath
        shapeLayer.shadowPath = shapeLayer.path
    }
    
    private func path(forRect rect: CGRect) -> UIBezierPath {
        
        let rowHeight = rect.size.height / CGFloat(rowsCount)
        let columnWidth = rect.size.width / CGFloat(columnsCount)
        
        let path = UIBezierPath()
        
        for row in 1 ..< rowsCount {
            
            let y = floor(CGFloat(row) * rowHeight)
            
            path.move(to: CGPoint(x: rect.origin.x, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        
        for column in 1 ..< columnsCount {
            
            let x = floor(CGFloat(column) * columnWidth)
            
            path.move(to: CGPoint(x: x, y: rect.origin.y))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        
        return path
    }
}
