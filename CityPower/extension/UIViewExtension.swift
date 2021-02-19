//
//  UIViewExtension.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 2/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxSwift
import RxCocoa


extension CardPartStackView {

    func addArrangedSubview(_ v:UIView, withMargin m:UIEdgeInsets )
    {
        let containerForMargin = UIView()
        containerForMargin.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: containerForMargin.topAnchor, constant:m.top ),
            v.bottomAnchor.constraint(equalTo: containerForMargin.bottomAnchor, constant: m.bottom ),
            v.leftAnchor.constraint(equalTo: containerForMargin.leftAnchor, constant: m.left),
            v.rightAnchor.constraint(equalTo: containerForMargin.rightAnchor, constant: m.right)
        ])

        addArrangedSubview(containerForMargin)
    }
}

extension UIAlertController {
    func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}



extension UIView {
    
    func addTopBoder() {
        let topView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: 1))
        topView.backgroundColor = UIColor.general.withAlphaComponent(0.5)
        addSubview(topView)
    }
    
    func addButtomBoder() {
        let buttomView = UIView(frame: CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: 1))
        buttomView.backgroundColor = UIColor.general.withAlphaComponent(0.5)
        addSubview(buttomView)
    }
}
