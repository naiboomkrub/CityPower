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

extension UIViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate  {
    
    func didTapOnImageView() {
        showAlert()
    }
    
    func showAlert() {

        let alert = UIAlertController(title: "Image Selection", message: "Where you want to pick the image?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .camera)
        }))
        alert.addAction(UIAlertAction(title: "Photo Album", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        alert.pruneNegativeWidthConstraints()
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
        
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            if sourceType == .camera {
                imagePickerController.allowsEditing = false
            } else {
                imagePickerController.allowsEditing = true
            }
            self.present(imagePickerController, animated: true, completion: nil)
            
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        //self.dismiss(animated: true) { [weak self] in

           // guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }

      //  }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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
