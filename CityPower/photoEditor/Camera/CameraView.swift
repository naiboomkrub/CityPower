//
//  CameraView.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 24/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


protocol CameraViewInput: class {
    
    func setTitle(_: String?)
    func setSubtitle(_: String?)
    func setOutputParameters(_: CameraOutputParameters)
    func setOutputOrientation(_: ExifOrientation)
    func setCameraHintVisible(_:Bool)
    func setCameraHint(text: String)
    
    var onFocusTap: ((_ focusPoint: CGPoint, _ touchPoint: CGPoint) -> Void)? { get set }
    func displayFocus(onPoint: CGPoint)
    
    var onAccessDeniedButtonTap: (() -> ())? { get set }
    
    func setAccessDeniedViewVisible(_: Bool)
}


final class CameraView: UIView, CameraViewInput {
        
    private let accessDeniedView = AccessDeniedView()
    private var cameraOutputView: CameraOutputView?
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let hintLabel = UILabel()
    private var outputParameters: CameraOutputParameters?
    private var focusIndicator: FocusIndicator?
    
    init() {
        super.init(frame: .zero)
        
        accessDeniedView.isHidden = true
        titleLabel.backgroundColor = .clear
        titleLabel.isUserInteractionEnabled = false
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.isUserInteractionEnabled = false
        
        accessDeniedView.titleLabel.text = "To take photo"
        accessDeniedView.messageLabel.text = "Allow CityPower to use your camera"
        accessDeniedView.button.setTitle("Allow access to camera", for: .normal)
        
        titleLabel.textColor = .black
        titleLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!
        subtitleLabel.textColor = .black
        subtitleLabel.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(18))!
        hintLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        hintLabel.textColor = .black
        
        addSubview(accessDeniedView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(hintLabel)
        
        setUpCameraHintLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelsTargetCenterY = CGFloat(27)
        
        accessDeniedView.bounds = bounds
        accessDeniedView.center = center
        
        cameraOutputView?.frame = bounds
        titleLabel.sizeToFit()
        subtitleLabel.sizeToFit()
        
        titleLabel.frame.origin.x = bounds.midX
        titleLabel.frame.origin.y = floor(labelsTargetCenterY - (titleLabel.bounds.height + subtitleLabel.bounds.height) / 2)
        
        subtitleLabel.frame.origin.x = bounds.midX
        subtitleLabel.frame.origin.y = titleLabel.bounds.maxY
        
        hintLabel.frame = CGRect(x: bounds.minX, y: bounds.maxY - 80, width: bounds.width, height: 80)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let screenSize = bounds.size
        guard screenSize.width != 0 && screenSize.height != 0 && accessDeniedView.isHidden == true  else {
            return
        }
        
        if let touchPoint = touches.first?.location(in: self) {
            let focusOriginX = touchPoint.y / screenSize.height
            let focusOriginY = 1.0 - touchPoint.x / screenSize.width
            let focusPoint = CGPoint(x: focusOriginX, y: focusOriginY)
            
            onFocusTap?(focusPoint, touchPoint)
        }
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
    
    func setSubtitle(_ subtitle: String?) {
        subtitleLabel.text = subtitle
    }
    
    var onFocusTap: ((_ focusPoint: CGPoint, _ touchPoint: CGPoint) -> Void)?
    
    func displayFocus(onPoint focusPoint: CGPoint) {
        focusIndicator?.hide()
        focusIndicator = FocusIndicator()
        focusIndicator?.setColor(UIColor(red: 0, green: 170.0/255, blue: 1, alpha: 1))
        focusIndicator?.animate(in: layer, focusPoint: focusPoint)
    }
    
    var onAccessDeniedButtonTap: (() -> ())? {
        get { return accessDeniedView.onButtonTap }
        set { accessDeniedView.onButtonTap = newValue }
    }
    
    func setAccessDeniedViewVisible(_ visible: Bool) {
        accessDeniedView.isHidden = !visible
    }
        
    func setOutputParameters(_ parameters: CameraOutputParameters) {
        
        let newCameraOutputView = CameraOutputView(captureSession: parameters.captureSession, outputOrientation: parameters.orientation)
        
        newCameraOutputView.alpha = 0.0
        
        cameraOutputView?.removeFromSuperview()
        
        addSubview(newCameraOutputView)
        
        bringSubviewToFront(titleLabel)
        bringSubviewToFront(subtitleLabel)
        bringSubviewToFront(hintLabel)
        
        self.cameraOutputView = newCameraOutputView
        self.outputParameters = parameters
        
        UIView.animate(withDuration: 0.5) {
            newCameraOutputView.alpha = 1.0
        }
    }
    
    func setOutputOrientation(_ orientation: ExifOrientation) {
        outputParameters?.orientation = orientation
        cameraOutputView?.orientation = orientation
    }
    
    func setCameraHint(text: String) {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.05
        style.minimumLineHeight = 24
        style.alignment = NSTextAlignment.center
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(
            NSAttributedString.Key.paragraphStyle,
            value: style,
            range: NSRange(location: 0, length: attributedString.length)
        )
        
        hintLabel.attributedText = attributedString
        hintLabel.isHidden = false
    }
    
    func setCameraHintVisible(_ visible: Bool) {
        let alpha = visible ? CGFloat(1) : CGFloat(0)
        UIView.animate(withDuration: 0.3) {
            self.hintLabel.alpha = alpha
        }
    }
    
    private var disposables = [AnyObject]()
    
    func addDisposable(_ object: AnyObject) {
        disposables.append(object)
    }
    
    private func setUpCameraHintLabel() {
        hintLabel.backgroundColor = .clear
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.isHidden = true
    }
}


final class FocusIndicator: CALayer {
    
    private let shapeLayer = CAShapeLayer()
    
    override init() {
        super.init()
        
        let radius = CGFloat(30)
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: 0,
            endAngle: .pi * 2, clockwise: true)

        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 2.0
                
        addSublayer(shapeLayer)
        
        bounds = CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setColor(_  color: UIColor) {
        shapeLayer.strokeColor = color.cgColor
    }
    
    func animate(in superlayer: CALayer, focusPoint: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        position = focusPoint
        
        superlayer.addSublayer(self)
        CATransaction.setCompletionBlock {
            self.removeFromSuperlayer()
        }
        
        self.add(FocusIndicatorScaleAnimation(), forKey: nil)
        self.add(FocusIndicatorOpacityAnimation(), forKey: nil)
        opacity = 0
        
        CATransaction.commit()
    }
    
    func hide() {
        removeAllAnimations()
        removeFromSuperlayer()
    }
}

final class FocusIndicatorScaleAnimation: CABasicAnimation {
    override init() {
        super.init()
        keyPath = "transform.scale"
        fromValue = 0.8
        toValue = 1.0
        duration = 0.3
        autoreverses = true
        isRemovedOnCompletion = false
        timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FocusIndicatorOpacityAnimation: CABasicAnimation {
    override init() {
        super.init()
        keyPath = "opacity"
        fromValue = 0
        toValue = 1.0
        duration = 0.3
        autoreverses = true
        isRemovedOnCompletion = false
        timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
