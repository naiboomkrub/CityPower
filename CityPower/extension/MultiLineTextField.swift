//
//  MultiLineTextField.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 15/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import UIKit


class MultilineTextField: UITextView {

    override var text: String! {
        didSet { setNeedsDisplay() }
    }
    
    var maxLength: Int = 0
    var trimWhiteSpaceWhenEndEditing: Bool = true
    
    var minHeight: CGFloat = 0 {
        didSet { forceLayoutSubviews() }
    }
    
    var maxHeight: CGFloat = 0 {
        didSet { forceLayoutSubviews() }
    }
    
    var placeholder: String? {
        didSet { setNeedsDisplay() }
    }
    
    var placeholderColor: UIColor = UIColor.placeholderText {
        didSet { setNeedsDisplay() }
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        textContainer.lineFragmentPadding = 0.0
        contentMode = .redraw
        associateConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange),
                                               name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidEndEditing),
                                               name: UITextView.textDidEndEditingNotification, object: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 30)
    }
    
    private func associateConstraints() {

        for constraint in constraints {
            if (constraint.firstAttribute == .height) {
                if (constraint.relation == .equal) {
                    heightConstraint = constraint;
                }
            }
        }
    }
    
    private var oldText: String = ""
    private var oldSize: CGSize = .zero
    private var heightConstraint: NSLayoutConstraint?
    
    private func forceLayoutSubviews() {
        oldSize = .zero
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private var shouldScrollAfterHeightChanged = false
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if text == oldText && bounds.size == oldSize { return }
        oldText = text
        oldSize = bounds.size
        
        let size = sizeThatFits(CGSize(width: bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        var height = size.height

        height = minHeight > 0 ? max(height, minHeight) : height
        height = maxHeight > 0 ? min(height, maxHeight) : height
        
        if (heightConstraint == nil) {
            heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
            addConstraint(heightConstraint!)
        }
        
        if height != heightConstraint!.constant {
            shouldScrollAfterHeightChanged = true
            heightConstraint!.constant = height

        } else if shouldScrollAfterHeightChanged {
            shouldScrollAfterHeightChanged = false
            scrollToCorrectPosition()
        }
    }
    
    private func scrollToCorrectPosition() {
        if self.isFirstResponder {
            self.scrollRangeToVisible(NSMakeRange(-1, 0))
        } else {
            self.scrollRangeToVisible(NSMakeRange(0, 0))
        }
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if text.isEmpty {
            let xValue = textContainerInset.left + textContainer.lineFragmentPadding
            let yValue = textContainerInset.top
            let width = rect.size.width - xValue - textContainerInset.right
            let height = rect.size.height - yValue - textContainerInset.bottom
            let placeholderRect = CGRect(x: xValue, y: yValue, width: width, height: height)
            
            if let placeholder = placeholder {
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = textAlignment
                var attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: placeholderColor,
                    .paragraphStyle: paragraphStyle
                ]
                if let font = font {
                    attributes[.font] = font
                }
                
                placeholder.draw(in: placeholderRect, withAttributes: attributes)
            }
        }
    }
    
    @objc func textDidEndEditing(notification: Notification) {
        if let sender = notification.object as? MultilineTextField, sender == self {
            if trimWhiteSpaceWhenEndEditing {
                text = text?.trimmingCharacters(in: .whitespacesAndNewlines)
                setNeedsDisplay()
            }
            scrollToCorrectPosition()
        }
    }
    
    @objc func textDidChange(notification: Notification) {
        if let sender = notification.object as? MultilineTextField, sender == self {
            if maxLength > 0 && text.count > maxLength {
                let endIndex = text.index(text.startIndex, offsetBy: maxLength)
                text = String(text[..<endIndex])
                undoManager?.removeAllActions()
            }
            setNeedsDisplay()
        }
    }
}

