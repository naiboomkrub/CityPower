//
//  SessionViewController.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 27/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class SessionViewController: UIViewController {
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var questionNumber: UILabel!
    @IBOutlet weak var quizContainer: UIView!
    @IBOutlet weak var timer: UIImageView!
    @IBOutlet weak var checkMove: NSLayoutConstraint!
    @IBOutlet weak var gear1: UIImageView!
    @IBOutlet weak var nextMove: NSLayoutConstraint!
    @IBOutlet weak var gear2Y: NSLayoutConstraint!
    @IBOutlet weak var gear2: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var toolBarHeight: NSLayoutConstraint!
    @IBOutlet weak var heightBg: NSLayoutConstraint!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var gear2Trail: NSLayoutConstraint!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var correctImage: UIImageView!
    
    var viewModel: SessionViewModel!
    var previousView: QuizViewController!
    var orient : UIDeviceOrientation!
    
    var currentRow = ""
    var prevLabel: UIButton?
    
    let gradient = CAGradientLayer()
    let gradient2 = CAGradientLayer()
    let gradientLayer = CAGradientLayer()
    let timerText = UILabel()
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    
    private let disposeBag = DisposeBag()
        
    @objc func willEnterForeground()
    {
        gear1.layer.add(rotateAnimation, forKey: "rotation.z")
        gear2.layer.add(rotateAnimation, forKey: "rotation.z")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                    
        setGradientBackground()

        NotificationCenter.default.addObserver(self, selector: #selector(self.willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
       
        rotateAnimation.toValue = CGFloat.pi * 2
        rotateAnimation.duration = 5.0
        rotateAnimation.isCumulative = true
        rotateAnimation.repeatCount = .infinity
        
        viewModel.enableButton.asObservable().bind(to: checkButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        checkButton.rx.tap.bind(onNext: viewModel.nextQuiz).disposed(by: disposeBag)
        viewModel.imageTimer.asObservable().bind(to: timer.rx.image).disposed(by: disposeBag)
        viewModel.timePro.asObservable().bind(to: timerText.rx.text).disposed(by: disposeBag)
        
        viewModel.timeNumber.bind(onNext: { [weak self] number in
            
            if number == 0 {
                UIView.animate(withDuration: 1.0,  delay: 0, options: .curveLinear, animations: {
                    self?.progressBar.layer.sublayers?.forEach { $0.removeAllAnimations() } })
            }
            else if number == 59 {
                self?.progressBar.setProgress(0.01, animated: false)
                UIView.animate(withDuration: 60,  delay: 0, options: .curveLinear, animations: {
                    self?.progressBar.layoutIfNeeded()
                })
            }
            else if number == 60 {
                self?.progressBar.progress = 1.0
            }
        }).disposed(by:disposeBag)
        
        viewModel.checkActions
            .subscribe(onNext: { [weak self] CheckAction in
            switch CheckAction {
            case .check:
                self?.nextMove.constant = -10
                UIView.transition(with: self!.view, duration: 0.3, options: .curveLinear, animations: {
                        self?.view.layoutIfNeeded()
                    }, completion: nil)
            case .swap:
                self?.checkMove.constant = -10
                self?.nextMove.constant = -120
                UIView.transition(with: self!.view, duration: 0.3, options: .curveLinear, animations: {
                    self?.view.layoutIfNeeded()
                    }, completion: nil)
            case .next:
                self?.checkMove.constant = -120
                UIView.transition(with: self!.view, duration: 0.3, options: .curveLinear, animations: {
                    self?.view.layoutIfNeeded()
                    }, completion: nil)
            case .start:
                self?.checkMove.constant = -120
                self?.nextMove.constant = -120
                self?.view.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
        
        timerText.frame = timer.bounds
        timerText.text = "Some Title"
        timerText.textAlignment = .center
        timerText.textColor = .white
        timerText.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))
        timer.addSubview(timerText)
        correctImage.isUserInteractionEnabled = false
        correctImage.alpha = 0

        viewModel.enableNext.asObservable().bind(to: nextButton.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        nextButton.rx.tap.bind(onNext: { [weak self] in
            self?.viewModel.checkQuiz()
            UIView.animate(withDuration: 0.5,  delay: 0, options: [.autoreverse, .transitionCrossDissolve], animations: {
                    self?.correctImage.alpha = 1
            }) { [weak self] finished in
                self?.correctImage.alpha = 0
            }
        }).disposed(by: disposeBag)
        
        viewModel.progressAttribute.asObservable().bind(to: questionNumber.rx.attributedText).disposed(by: disposeBag)
        viewModel.checkCorrect.asObservable().bind(to: correctImage.rx.image).disposed(by: disposeBag)
        viewModel.colorGrad.asObservable().subscribe (onNext: { [weak self] color in
            self?.gradientLayer.colors = color.map {$0.cgColor}
        }).disposed(by: disposeBag)
    
        viewModel.viewStackActions
            .subscribe(onNext: { [weak self] ViewStackAction in
        switch ViewStackAction {
            
        case .set(let viewModel):
            
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            GameSession.shared.mGameController.append(viewController as! QuizViewController)
            
            self?.addChild(viewController)
            let bound = self?.quizContainer.bounds
            viewController.view.frame = bound!
            viewController.view.backgroundColor = .clear
            self?.previousView = viewController as? QuizViewController
  
            UIView.transition(with: (self?.quizContainer)!, duration: 0.4, options: [.curveEaseIn], animations: { self?.quizContainer.addSubview(viewController.view)
                }, completion: nil)
            viewController.didMove(toParent: self)
        
        case .push(let viewModel):
            
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            GameSession.shared.mGameController.append(viewController as! QuizViewController)
            
            self?.addChild(viewController)
            self?.quizContainer.addSubview(viewController.view)
            viewController.view.frame.origin.x = (self?.view.bounds.width)!
            viewController.view.backgroundColor = .clear
            
            UIView.transition( with: (self?.quizContainer)!, duration:0.4, options: UIView.AnimationOptions.beginFromCurrentState, animations: {
                let bound = self?.quizContainer.bounds
                viewController.view.frame = bound!
                self?.previousView.view.frame.origin.x = -(self?.view.bounds.width)!
                
                }, completion: { (finish) in
                    viewController.didMove(toParent: self)
                    self?.previousView.view.removeFromSuperview()
                    self?.previousView.removeFromParent()
                    self?.previousView = viewController as? QuizViewController
            })
        case .end:
            
            UIView.animate(withDuration: 0.2, animations: {
                self?.previousView.view.alpha = 0.0
            }, completion: {(value : Bool) in
                self?.previousView.view.removeFromSuperview()
                self?.previousView.removeFromParent()
            })
        }
        }).disposed(by: disposeBag)
        
        viewModel.category.asObservable().subscribe(onNext: { [weak self] category in
            
            let maxLabelWidth: CGFloat = 170
            let font = UIFont(name: "Baskerville-Bold", size: CGFloat(24))!
            let spaceWidth = NSString(string: " ").size(withAttributes: [NSAttributedString.Key.font: font]).width
            let subStrings = category.split(separator: " ")
  
            var currentRowWidth: CGFloat = 0.0
            
            for subString in subStrings {
                
                let currentWord = String(subString)
                let nsCurrentWord = NSString(string: currentWord)
                let currentWordWidth = nsCurrentWord.size(withAttributes: [NSAttributedString.Key.font: font]).width
                let currentWidth = self?.currentRow.count == 0 ? currentWordWidth : currentWordWidth + spaceWidth + currentRowWidth

                 if currentWidth <= maxLabelWidth {
                    currentRowWidth = currentWidth
                    self?.currentRow += self?.currentRow.count == 0 ? currentWord : " " + currentWord
                 } else {
                    self?.prevLabel = self?.generateLabel(with: self!.currentRow, font: font,
                                                          prevLabel: self?.prevLabel)
                    currentRowWidth = currentWordWidth
                    self?.currentRow =  currentWord
                 }
            }
            self?.generateLabel(with: self!.currentRow, font: font, prevLabel: self?.prevLabel)
            currentRowWidth = 0
            self?.currentRow =  ""
            
        }).disposed(by: disposeBag)
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            
        let orientation = UIDevice.current.orientation
        if orientation == .portrait {
            self.gear2Y.constant = 40
            self.gear2Trail.constant = -5
     
            let newConstraint = self.toolBarHeight.constraintWithMultiplier(0.12)
            self.view.removeConstraint(self.toolBarHeight)
            self.view.addConstraint(newConstraint)
            self.toolBarHeight = newConstraint
        }
        else {
            self.gear2Y.constant = 35
            self.gear2Trail.constant = -10
            
            let newConstraint = self.toolBarHeight.constraintWithMultiplier(0.2)
            self.view.removeConstraint(self.toolBarHeight)
            self.view.addConstraint(newConstraint)
            self.toolBarHeight = newConstraint
        }
        self.view.layoutIfNeeded()
      }, completion: {
          _ in
      })
  }
  
    func setGradientBackground() {
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = self.view.bounds
                
        self.view.layer.insertSublayer(gradientLayer, at:0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let orientation = UIDevice.current.orientation
        
        if orientation != self.orient {
            if orientation == .portrait {
                self.gear2Y.constant = 40
                self.gear2Trail.constant = -5
            }
            else {
                self.gear2Y.constant = 35
                self.gear2Trail.constant = -10
                
                let newConstraint = self.toolBarHeight.constraintWithMultiplier(0.2)
                self.view.removeConstraint(self.toolBarHeight)
                self.view.addConstraint(newConstraint)
                self.toolBarHeight = newConstraint
            }
        }
        self.orient = UIDevice.current.orientation
        self.view.layoutIfNeeded()
    
        heightBg.constant = view.safeAreaInsets.top + 95
        gradientLayer.frame = self.view.bounds
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.gear1.layer.removeAllAnimations()
        self.gear2.layer.removeAllAnimations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        gear1.layer.add(rotateAnimation, forKey: "rotation.z")
        gear2.layer.add(rotateAnimation, forKey: "rotation.z")
        
    }
    
    @discardableResult func generateLabel(with text: String, font: UIFont, prevLabel: UIButton?) -> UIButton {
       
        let label = UIButton()
        label.translatesAutoresizingMaskIntoConstraints = false
        category.addSubview(label)
        label.leftAnchor.constraint(equalTo: category.leftAnchor).isActive = true
        if let prevLabel = prevLabel {
            label.topAnchor.constraint(equalTo: prevLabel.bottomAnchor).isActive = true
        } else {
            label.topAnchor.constraint(equalTo: category.topAnchor).isActive = true
        }
        
        label.titleLabel?.textAlignment = .left
        label.titleLabel?.font = font
        label.contentEdgeInsets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
        label.setTitle(text , for: .normal)
        label.backgroundColor = .blueCity
        label.isUserInteractionEnabled = false

        return label
    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}

