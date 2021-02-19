//
//  CustomActivityIndicator.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 16/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation

class CustomActivityIndicatorView: UIView {
    
    lazy private var animationLayer : CALayer = {
        return CALayer()
    }()
    
    var isAnimating : Bool = false
    var hidesWhenStopped : Bool = true
    
    public init(image : UIImage?) {
        
        var frame : CGRect
        var loadingImage: UIImage!
        
        if let image = image {
            loadingImage = image
            frame = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
        }
        else {
            let bundle = Bundle(for: CustomActivityIndicatorView.self)
            let image = UIImage(named: "loading.png", in: bundle, compatibleWith: nil)!
            loadingImage = image
            frame = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
        }
        

        super.init(frame: frame)
        
        animationLayer.frame = frame
        animationLayer.contents = loadingImage.cgImage
        animationLayer.masksToBounds = true
        
        self.layer.addSublayer(animationLayer)
        
        addRotation(forLayer: animationLayer)
        pause(layer: animationLayer)
        self.isHidden = true
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func addRotation(forLayer layer : CALayer) {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
        
        rotation.duration = 1.0
        rotation.isRemovedOnCompletion = false
        rotation.repeatCount = HUGE
        rotation.fillMode = CAMediaTimingFillMode.forwards
        rotation.fromValue = NSNumber(value: 0.0)
        rotation.toValue = NSNumber(value: 3.14 * 2.0)
        
        layer.add(rotation, forKey: "rotate")
    }
    
    public func pause(layer : CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        
        layer.speed = 0.0
        layer.timeOffset = pausedTime
        
        isAnimating = false
    }
    
    public func resume(layer : CALayer) {
        let pausedTime : CFTimeInterval = layer.timeOffset
        
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
        
        isAnimating = true
    }
    
    public func startAnimating () {
        
        if isAnimating {
            return
        }
        
        if hidesWhenStopped {
            self.isHidden = false
        }
        resume(layer: animationLayer)
    }
    
    public func stopAnimating () {
        if hidesWhenStopped {
            self.isHidden = true
        }
        pause(layer: animationLayer)
    }
}
