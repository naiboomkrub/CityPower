//
//  AccessDeniedView.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 6/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


final class AccessDeniedView: UIView {
    
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let button = UIButton()
    
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var message: String? {
        get { return messageLabel.text }
        set { messageLabel.text = newValue }
    }
    
    var buttonTitle: String? {
        get { return button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }
    
    var onButtonTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
                
        titleLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        messageLabel.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(18))!
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        button.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(22))!
        button.backgroundColor = UIColor.lightGray
        button.layer.cornerRadius = 4
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)
        
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let frames = calculateFrames(forBounds: CGRect(origin: .zero, size: size))
        return CGSize(width: size.width, height: frames.buttonFrame.maxY)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frames = calculateFrames(forBounds: bounds)
        
        titleLabel.frame = frames.titleLabelFrame
        messageLabel.frame = frames.messageLabelFrame
        button.frame = frames.buttonFrame
    }
    
    // MARK: - Private
    
    private func calculateFrames(forBounds bounds: CGRect) -> (titleLabelFrame: CGRect, messageLabelFrame: CGRect, buttonFrame: CGRect) {
        
        let titleBottomMargin: CGFloat = 7
        let messageBottomMargin: CGFloat = 34
        let buttonHeight: CGFloat = 52
        
        let labelsWidth = bounds.size.width * 0.8
        let titleSize = titleLabel.sizeThatFits(CGSize(width: labelsWidth, height: .greatestFiniteMagnitude))
        let messageSize = messageLabel.sizeThatFits(CGSize(width: labelsWidth, height: .greatestFiniteMagnitude))
        
        let contentHeight = titleSize.height + titleBottomMargin + messageSize.height + messageBottomMargin + buttonHeight
        let contentTop = max(0, bounds.minY + (bounds.size.height - contentHeight) / 2)
        
        var titleLabelFrame = CGRect(origin: CGPoint(x: 0, y: contentTop), size: titleSize)
        
        titleLabelFrame.origin.x = bounds.origin.x + bounds.width / 2 - titleLabelFrame.width / 2
        
        var messageLabelFrame = CGRect(origin: .zero, size: messageSize)
        
        messageLabelFrame.origin.x = bounds.origin.x + bounds.width / 2 - messageLabelFrame.width / 2
        messageLabelFrame.origin.y = titleLabelFrame.maxY + titleBottomMargin
        
        var buttonFrame = CGRect(origin: .zero, size: button.sizeThatFits(bounds.size))
        buttonFrame.origin.x = bounds.origin.x + bounds.width / 2 - buttonFrame.width / 2
        buttonFrame.origin.y = messageLabelFrame.maxY + messageBottomMargin
        buttonFrame.size.height = buttonHeight
        
        return (titleLabelFrame: titleLabelFrame, messageLabelFrame: messageLabelFrame, buttonFrame: buttonFrame)
    }
    
    @objc private func onButtonTap(_: UIButton) {
        onButtonTap?()
    }
}
