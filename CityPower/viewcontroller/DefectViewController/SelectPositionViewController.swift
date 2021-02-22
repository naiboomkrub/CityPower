//
//  SelectPositionViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 10/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift


class SelectPositionViewController: UIViewController, UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var viewModel: SelectPositionViewModel!
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var planPicture: UIImageView!
    
    private let disposeBag = DisposeBag()
    
    private var completion = { }
    private var annotationsToSelect = [UIView]()
    private var positionKey: [UIView: CGPoint] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectTag))
        tap.delegate = self
        
        planPicture.removeGesture()
        planPicture.isUserInteractionEnabled = true
        planPicture.addGestureRecognizer(tap)
        
        confirmButton.rx.tap.bind(onNext: { [weak self] in
            
            guard let selectedPos = self?.annotationsToSelect.first as? TemView,
                  let text = selectedPos.labelNum.text,
                  let dicResult = self?.positionKey[selectedPos] else { return }
            self?.viewModel.savePosition()
            self?.viewModel.positionSelected.accept([dicResult, text])

        }).disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.imageName, viewModel.positionDefect)
            .subscribe(onNext: { [weak self] image, position in
            
            guard let url = URL(string: image) else { return }
            
            self?.completion = {
                DispatchQueue.main.async {
                    if !position.isEmpty,
                       let width = self?.planPicture.frame.width,
                       let height = self?.planPicture.frame.height,
                       let imgSize = self?.planPicture.image?.size {

                        let aspectWidth  = width / imgSize.width
                        let aspectHeight = height / imgSize.height
                        let f = min(aspectWidth, aspectHeight)

                        for pos in position {

                            var imagePoint = pos.value

                            imagePoint.y *= f
                            imagePoint.x *= f
                            imagePoint.x += (width - imgSize.width * f) / 2.0
                            imagePoint.y += (height - imgSize.height * f) / 2.0

                            let tempView = TemView()
                            tempView.setText("\(pos.key)")
                            tempView.bounds.size = CGSize(width: 50, height: 70)
                            tempView.frame.origin = imagePoint
                            tempView.layer.borderColor = UIColor.blueCity.cgColor
                            tempView.backgroundColor = .clear
                            self?.planPicture.addSubview(tempView)
                            self?.positionKey[tempView] = pos.value
                            
                        }
                    }
                }
            }

            let pipeline = DataPipeLine.shared
            let request = DataRequest(url: url, processors: [])

            if let container = pipeline.cachedImage(for: request) {
                self?.planPicture.image = container.image
                self?.completion()
                return
            }
            
            pipeline.loadImage(with: request) { [weak self] result in
                if case let .success(response) = result {
                    self?.planPicture.image = response.image
                    self?.completion()
                }
            }

        }).disposed(by: disposeBag)

    }
    
    @objc func selectTag(_ sender: UITapGestureRecognizer) {

        let position = sender.location(in: planPicture)
            
        for view in planPicture.subviews {
            let annotationBound = view.frame
            if annotationBound.contains(position) && !annotationsToSelect.contains(view) {
                for annotate in annotationsToSelect {
                    annotate.layer.borderWidth = 0.0
                }
                annotationsToSelect.removeAll()
                view.layer.borderWidth = 1.0
                annotationsToSelect.append(view)
            } else if annotationBound.contains(position) {
                view.layer.borderWidth = 0.0
                
                if let index = annotationsToSelect.firstIndex(of: view) {
                    annotationsToSelect.remove(at: index)
                }
            }
        }
    }
}

