//
//  InfoMessageView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


public protocol InfoMessageViewInput: class {
    func dismiss()
}

protocol InfoMessageViewFactory: class {
    
    func create(from viewData: InfoMessageViewData) -> (view: InfoMessageView, animator: InfoMessageAnimator)
}


final class InfoMessageViewFactoryImpl: InfoMessageViewFactory {
    
    func create(from viewData: InfoMessageViewData) -> (view: InfoMessageView, animator: InfoMessageAnimator) {
      
        let animation = DefaultInfoMessageAnimatorBehavior()
        let data = InfoMessageAnimatorData(animation: animation, timeout: viewData.timeout, onDismiss: nil)
        let animator = InfoMessageAnimator(data)
        
        let messageView = InfoMessageView()
        messageView.setViewData(viewData)
        
        return (view: messageView, animator: animator)
    }
}


protocol InfoMessageAnimatorBehavior {
    func configure(messageView: UIView, in container: UIView)
    func present(messageView: UIView, in container: UIView)
    func dismiss(messageView: UIView, in container: UIView)
}


final class DefaultInfoMessageAnimatorBehavior: InfoMessageAnimatorBehavior {
    
    func configure(messageView: UIView, in container: UIView) {
        messageView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        messageView.alpha = 0
        
        let bottomInset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 154 : 20
        messageView.frame.origin.y = bottomInset
        messageView.frame.origin.x = 0
    }
    
    func present(messageView: UIView, in container: UIView) {
        messageView.alpha = 1
    }
    
    func dismiss(messageView: UIView, in container: UIView) {
        messageView.alpha = 0
    }
}


struct InfoMessageViewData {
    let text: String
    let timeout: TimeInterval
    let font: UIFont?
}

final class InfoMessageView: UIView {
    
    private struct Layout {
        static let height: CGFloat = 26
        static let textInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        static let widthTextInsets = textInsets.left + textInsets.right
        static let heightTextInsets = textInsets.top + textInsets.bottom
    }
    
    private struct Spec {
        static let textColor = UIColor.black
        static let cornerRadius: CGFloat = 2
        static let backgroundColor = UIColor.white
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowOpacity: Float = 0.14
        static let shadowRadius: CGFloat = 2
    }
    
    private let textLabel = UILabel()
    private let contentView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(contentView)
        
        contentView.layer.cornerRadius = Spec.cornerRadius
        contentView.layer.masksToBounds = true
        
        textLabel.textColor = Spec.textColor
        contentView.addSubview(textLabel)
        
        contentView.backgroundColor = Spec.backgroundColor
        
        layer.masksToBounds = false
        layer.shadowOffset = Spec.shadowOffset
        layer.shadowRadius = Spec.shadowRadius
        layer.shadowOpacity = Spec.shadowOpacity
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setViewData(_ viewData: InfoMessageViewData) {
        textLabel.font = viewData.font
        textLabel.text = viewData.text
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel.frame = CGRect(
            x: Layout.textInsets.left,
            y: Layout.textInsets.top,
            width:  bounds.width - Layout.widthTextInsets,
            height: bounds.height - Layout.heightTextInsets
        )
        
        contentView.frame = bounds
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let shrinkedSize = CGSize(
            width: size.width - Layout.widthTextInsets,
            height: Layout.height - Layout.heightTextInsets
        )
        
        let textSize = textLabel.sizeThatFits(shrinkedSize)
        
        return CGSize(
            width: textSize.width + Layout.widthTextInsets,
            height: Layout.height
        )
    }
}
