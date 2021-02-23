//
//  MoveLayer.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 9/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation

class LayerMove: UIGestureRecognizer  {
        
    private var annotationBeingDragged: TemView?
    private var pdfView : UIImageView!
    private var drawVeil = UIView()
    private var moveView = TemView()
    private var centerEnd: CGPoint?
    
    private func getCurrentPage() {
        
        if let possiblePDFViews = self.view as? UIImageView {
            pdfView = possiblePDFViews
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        getCurrentPage()
        
        if let touch = touches.first {
            
            DispatchQueue.main.async {
                
                let currentLocation = touch.location(in: self.pdfView)
                let center = CGPoint(x: currentLocation.x - 25, y: currentLocation.y - 35)

                for view in self.pdfView.subviews {
                    let annotationBound = view.frame
                    if annotationBound.contains(currentLocation),
                       let superView = self.pdfView.superview,
                       let view = view as? TemView,
                       let text = view.labelNum.text {
                        
                        self.drawVeil = UIView(frame: self.pdfView.frame)
                        superView.addSubview(self.drawVeil)
                        self.drawVeil.isUserInteractionEnabled = false
                        self.annotationBeingDragged = view
                        
                        view.removeFromSuperview()
                        
                        self.moveView.frame = CGRect(x: center.x, y: center.y, width: 50, height: 70)
                        self.moveView.setText(text)
                        self.moveView.backgroundColor = .clear
                        self.drawVeil.addSubview(self.moveView)
                        break
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if annotationBeingDragged == nil { return }
        
        if  let view = self.annotationBeingDragged, let touch = touches.first {
            DispatchQueue.main.async {
                
                let currentPoint = touch.location(in: self.pdfView)
                let areaDrag = CGRect(x: view.bounds.width / 2, y: view.bounds.height / 2, width: self.pdfView.bounds.width - view.bounds.width / 2, height: self.pdfView.bounds.height - view.bounds.height / 2)
                let center2 = CGPoint(x: currentPoint.x, y: currentPoint.y)
                
                if center2.x < areaDrag.origin.x {
                    if center2.y < areaDrag.origin.y {
                        self.moveView.center = CGPoint(x: areaDrag.origin.x, y: areaDrag.origin.y)
                    } else if center2.y > areaDrag.height {
                        self.moveView.center = CGPoint(x: areaDrag.origin.x, y: areaDrag.height)
                    } else {
                        self.moveView.center = CGPoint(x: areaDrag.origin.x, y: center2.y)
                    }
                } else if center2.y < areaDrag.origin.y {
                    
                    if center2.x < areaDrag.origin.x {
                        self.moveView.center = CGPoint(x: areaDrag.origin.x, y: areaDrag.origin.y)
                    } else if center2.x > areaDrag.width {
                        self.moveView.center = CGPoint(x: areaDrag.width, y: areaDrag.origin.y)
                    } else {
                        self.moveView.center = CGPoint(x: center2.x, y: areaDrag.origin.y)
                    }
                } else if center2.y > areaDrag.height {
                    
                    if center2.x < areaDrag.origin.x {
                        self.moveView.center = CGPoint(x: areaDrag.origin.x, y: areaDrag.height)
                    } else if center2.x > areaDrag.width {
                        self.moveView.center = CGPoint(x: areaDrag.width, y: areaDrag.height)
                    } else {
                        self.moveView.center = CGPoint(x: center2.x, y: areaDrag.height)
                    }
                    
                } else if center2.x > areaDrag.width {
                    if center2.y < areaDrag.origin.y {
                        self.moveView.center = CGPoint(x: areaDrag.width, y: areaDrag.origin.y)
                    } else if center2.y > areaDrag.height {
                        self.moveView.center = CGPoint(x: areaDrag.width, y: areaDrag.height)
                    } else {
                        self.moveView.center = CGPoint(x: areaDrag.width, y: center2.y)
                    }
                    
                } else {
                    self.moveView.center = center2
                }
                self.centerEnd = self.moveView.center
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if annotationBeingDragged == nil { return }
        
        if let view = self.annotationBeingDragged, let centerEnd = self.centerEnd, let text = view.labelNum.text {
            DispatchQueue.main.async {
                
                let centerEnd = CGPoint(x: centerEnd.x - view.bounds.width / 2, y: centerEnd.y - view.bounds.height / 2)
                
                if let convertedPoint = convertViewToImagePoint(self.pdfView, view.frame.origin),
                   let centerConverted = convertViewToImagePoint(self.pdfView, centerEnd) {
                    DefectDetails.shared.movePoint(ImagePosition(x: Double(convertedPoint.x), y: Double(convertedPoint.y), pointNum: text), ImagePosition(x: Double(centerConverted.x), y: Double(centerConverted.y), pointNum: text))
                }
                
                view.frame = CGRect(origin: centerEnd, size: view.bounds.size)
                self.pdfView.addSubview(view)
                self.drawVeil.removeFromSuperview()
                self.annotationBeingDragged = nil
                self.centerEnd = nil
            }
        }
    }
}

class TemView : UIView {
    
    let labelNum = UILabel()
    
    override class var layerClass : AnyClass {
        return TemLayer.self
    }
    
    override func draw(_ rect: CGRect) {
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        labelNum.backgroundColor = .clear
        labelNum.text = "1"
        labelNum.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(12))!
        labelNum.textColor = .white
        labelNum.sizeToFit()
        
        addSubview(labelNum)
        labelNum.translatesAutoresizingMaskIntoConstraints = false
        labelNum.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        labelNum.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func setText(_ text: String) {
        labelNum.text = text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class TemLayer : CALayer {
    
    override func draw(in ctx: CGContext) {
        
        UIGraphicsPushContext(ctx)
        ctx.saveGState()
        
        let rectangle = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        let borderRect = rectangle.insetBy(dx: 10 * 0.5, dy: 30 * 0.5)
        
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.move(to: CGPoint(x:self.bounds.midX, y:self.bounds.maxY - 12.5))
        ctx.addLine(to: CGPoint(x: self.bounds.midX, y: self.bounds.maxY))
        ctx.setLineWidth(1)
        ctx.strokePath()
        
        ctx.setFillColor(UIColor.blueCity.cgColor)
        ctx.setStrokeColor(UIColor.lightBlueCity.cgColor)
        ctx.setLineWidth(7.5)
        ctx.setTextDrawingMode(.fill)
        
        ctx.addEllipse(in: borderRect)
        ctx.drawPath(using: .fillStroke)
                    
        ctx.restoreGState()
        UIGraphicsPopContext()
    }
}


extension String {

    func drawFlipped(in rect: CGRect, withAttributes attributes: [NSAttributedString.Key : Any]) {
        guard let gc = UIGraphicsGetCurrentContext() else { return }
        gc.saveGState()
        defer { gc.restoreGState() }
        gc.translateBy(x: rect.origin.x, y: rect.origin.y + 15 + rect.size.height / 2)
        gc.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(origin: .zero, size: rect.size), withAttributes: attributes)
    }
    
    func drawOffset(in rect: CGRect, withAttributes attributes: [NSAttributedString.Key : Any]) {
        guard let gc = UIGraphicsGetCurrentContext() else { return }
        gc.saveGState()
        defer { gc.restoreGState() }
        gc.translateBy(x: rect.origin.x, y: rect.origin.y + 10)
        self.draw(in: CGRect(origin: .zero, size: rect.size), withAttributes: attributes)
    }

}
