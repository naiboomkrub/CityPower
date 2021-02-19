//
//  DefectViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts
import RxSwift
import PDFKit

class DefectViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var safeView: UIView!
    
    var viewModel: DefectViewModel!
    var pdfView: PDFViewer!
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pdfView = PDFViewer()
        self.pdfView = pdfView
        
        pdfView.frame = safeView.bounds
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .blueCity
        
        safeView.addSubview(pdfView)
        
        //let tap = UITapGestureRecognizer(target: self, action: #selector(deleteAnnotation))
        //tap.delegate = self
        //pdfView.addGestureRecognizer(tap)
        
        let anoView = TemView()
        anoView.backgroundColor = .clear
        anoView.frame = CGRect(x: 100.0, y: 100.0, width: 70, height: 70)
        
        safeView.addSubview(anoView)
        
        let pan = AnnotationMove()
        //pdfView.isUserInteractionEnabled = false
        pdfView.addGestureRecognizer(pan)
        
        createPdfDocument(forFileName: "http://www.africau.edu/images/default/sample.pdf")
        drawImage()
    }
    
    private func drawImage() {
        
        guard let signatureImage = UIImage(named: "Asset 11"), let page = pdfView.currentPage else { return }
        let pageBounds = page.bounds(for: .cropBox)
        let imageBounds = CGRect(x: pageBounds.midX, y: pageBounds.midY, width: 100, height: 100)
        let imageStamp = ImageStampAnnotation(with: signatureImage, forBounds: imageBounds, withProperties: nil)
        pdfView.document?.page(at: 0)?.addAnnotation(imageStamp)
    }
    
    private func createPdfDocument(forFileName fileName: String) {
        
        guard let path = URL(string: fileName) else { return }
        if let document = PDFDocument(url: path) {
            pdfView.document = document
        }
    }
    
    @objc func deleteAnnotation(_ sender: UITapGestureRecognizer) {

        let position = sender.location(in: pdfView)
        guard let page = pdfView.page(for: position, nearest: true) else { return }
        let locationOnPage = pdfView.convert(position, to: page)
        let annotationsToDelete = NSMutableArray()
            
        if let annotations: [PDFAnnotation] = pdfView.currentPage?.annotations {
            for annotation in annotations {
                let annotationBound = annotation.bounds
                if annotationBound.contains(locationOnPage) {
                    annotationsToDelete.add(annotation)
                }
            }
            for annotation in annotationsToDelete {
                let onlyHighlight = annotation as! PDFAnnotation
                pdfView.currentPage?.removeAnnotation(onlyHighlight)
            }
        }
    }
}


class PDFViewer: PDFView {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
}


class ImageStampAnnotation: PDFAnnotation {

    var image: UIImage!

    init(with image: UIImage!, forBounds bounds: CGRect, withProperties properties: [AnyHashable : Any]?) {
        super.init(bounds: bounds, forType: PDFAnnotationSubtype.stamp, withProperties: properties)

        self.image = image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {

        UIGraphicsPushContext(context)
        context.saveGState()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key : Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!,
            .foregroundColor: UIColor.white
        ]
        
        let text = "BOOM"
        let rectangle = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: self.bounds.width - 10, height: self.bounds.height - 10)
        let borderRect = rectangle.insetBy(dx: 10 * 0.5, dy: 10 * 0.5)
        
        context.setFillColor(UIColor.blueCity.cgColor)
        context.setStrokeColor(UIColor.lightBlueCity.cgColor)
        context.setLineWidth(10)
        context.setTextDrawingMode(.fill)
        
        context.addEllipse(in: borderRect)
        context.drawPath(using: .fillStroke)
        text.drawFlipped(in: borderRect, withAttributes: attributes)
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}


class AnnotationMove: UIGestureRecognizer  {
        
    private var annotationBeingDragged: PDFAnnotation!
    private var pdfView : PDFViewer!
    private var currentPDFPage : PDFPage!
    private var drawVeil = UIView()
    private var moveView = TemView()
    
    private func getCurrentPage() -> Bool {
        if let possiblePDFViews = self.view as? PDFViewer {
            pdfView = possiblePDFViews
        }
        
        if pdfView.document == nil  { return false }
        if let currentPDFPageTest = pdfView.document!.page(at: (pdfView.document!.index(for: (pdfView.currentPage ?? PDFPage())))) {
            currentPDFPage = currentPDFPageTest
        } else {
            return false
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !getCurrentPage() {
            return
        }
        if let touch = touches.first {
            
            DispatchQueue.main.async {
                
                self.drawVeil = UIView(frame: self.pdfView.frame)
                self.pdfView.superview!.addSubview(self.drawVeil)
                self.drawVeil.isUserInteractionEnabled = false
                
                let currentLocation = touch.location(in: self.pdfView)
                let locationOnPage = self.pdfView.convert(currentLocation, to: self.currentPDFPage)
                let annotations = self.currentPDFPage.annotations
                let center = CGPoint(x: currentLocation.x - 27.5, y: currentLocation.y - 27.5)

                for annotation in annotations {
                    let annotationBound = annotation.bounds
                    if annotationBound.contains(locationOnPage) {
                        self.annotationBeingDragged = annotation
                        self.currentPDFPage.removeAnnotation(annotation)
                        self.moveView.frame = CGRect(x: center.x, y: center.y, width: 60, height: 60)
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
        
        if let touch = touches.first {
            DispatchQueue.main.async {
                let currentPoint = touch.location(in: self.pdfView)
                let center2 = CGPoint(x: currentPoint.x, y: currentPoint.y)
                self.moveView.center = center2
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if annotationBeingDragged == nil { return }
        
        if let annotation = self.annotationBeingDragged, let touch = touches.first {
            DispatchQueue.main.async {
                let currentPoint = touch.location(in: self.pdfView)
                let locationOnPage = self.pdfView.convert(currentPoint, to: self.currentPDFPage)
                let center = CGPoint(x: locationOnPage.x - annotation.bounds.width / 2, y: locationOnPage.y - annotation.bounds.height / 2)
                annotation.bounds = CGRect(origin: center, size: annotation.bounds.size)
                self.currentPDFPage.addAnnotation(annotation)
                self.annotationBeingDragged = nil
                self.moveView.removeFromSuperview()
            }
        }
    }
}


