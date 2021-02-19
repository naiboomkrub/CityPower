//
//  QuizViewController.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import CardParts
import RxCocoa
import RxSwift


class QuizViewController: CardsViewController {
    
    var quizController: QuizController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cards: [CardController] = [quizController]
        self.view.subviews.first?.backgroundColor = .clear
        loadCards(cards: cards)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.viewWillTransition(to: self.view.frame.size, with: coordinator)
        }, completion: {
            _ in
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.viewDidAppear(false)
    }
}


class QuizController: CardPartsViewController, UIScrollViewDelegate, TransparentCardTrait {
    
    var viewModel: QuizViewModel!
    var pastChoice: CardPartButtonView!
    
    let questionImage = CardPartImageView()
    let textQuestion = CardPartTitleView(type: .titleOnly)
    let titlePart = CardPartTitleView(type: .titleOnly)
    let choice1 = CardPartButtonView()
    let choice2 = CardPartButtonView()
    let choice3 = CardPartButtonView()
    let choice4 = CardPartButtonView()
    let choice5 = CardPartButtonView()
    let imageStack = CardPartStackView()
    let imageCaption = CardPartTextView(type: .small)
    
    let attrs = [NSAttributedString.Key.font : UIFont(name: "Baskerville-Bold", size: CGFloat(10))!, NSAttributedString.Key.foregroundColor : UIColor.Gray3]
    let enlarge = NSTextAttachment()
    let bgLayer = CALayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bgLayer.contents = #imageLiteral(resourceName: "quiz bg0").cgImage
        view.layer.insertSublayer(bgLayer, at: 0)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        questionImage.isUserInteractionEnabled = true
        questionImage.addGestureRecognizer(tap)
        
        viewModel.title.asObservable().bind(to: questionImage.rx.imageName).disposed(by: bag)
        viewModel.title.asObservable().bind(to: titlePart.rx.title).disposed(by: bag)
        viewModel.title1.asObservable().bind(to: choice1.rx.buttonTitle).disposed(by: bag)
        viewModel.title2.asObservable().bind(to: choice2.rx.buttonTitle).disposed(by: bag)
        viewModel.title3.asObservable().bind(to: choice3.rx.buttonTitle).disposed(by: bag)
        viewModel.title4.asObservable().bind(to: choice4.rx.buttonTitle).disposed(by: bag)
        viewModel.title5.asObservable().bind(to: choice5.rx.buttonTitle).disposed(by: bag)
        
        viewModel.color1.asObservable().bind(to: choice1.rx.backgroundColor).disposed(by: bag)
        viewModel.color2.asObservable().bind(to: choice2.rx.backgroundColor).disposed(by: bag)
        viewModel.color3.asObservable().bind(to: choice3.rx.backgroundColor).disposed(by: bag)
        viewModel.color4.asObservable().bind(to: choice4.rx.backgroundColor).disposed(by: bag)
        viewModel.color5.asObservable().bind(to: choice5.rx.backgroundColor).disposed(by: bag)
        
        [choice1,choice2,choice3,choice4,choice5].enumerated().forEach { [weak self] index, choice in
            
            choice.layer.backgroundColor = UIColor.white.cgColor
            choice.layer.cornerRadius = 25
            choice.contentHorizontalAlignment = .center
            choice.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
            choice.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
            choice.layer.shadowOpacity = 0.8
            choice.layer.shadowRadius = 2.0
            choice.layer.borderColor = UIColor.border.cgColor
            choice.layer.masksToBounds = false
            choice.margins = UIEdgeInsets(top: 0.0, left: 95.0, bottom: 25.0, right: 95.0)
            choice.titleLabel?.font = choice.titleLabel?.font.withSize(24)
            
            viewModel.enableButton.asObservable().bind(to: choice.rx.isEnabled).disposed(by: bag)
            choice.rx.tap.bind(onNext: {
                self?.viewModel.onChoiceClick(index)
                
                choice.layer.borderWidth = 1.0
                choice.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                UIView.animate(withDuration: 0.2, animations: {
                    choice.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }, completion: { _ in
                        if self?.pastChoice != nil && self?.pastChoice != choice {
                            self?.pastChoice.layer.borderWidth = 0.0
                            UIView.animate(withDuration: 0.2) {
                                self?.pastChoice.transform = CGAffineTransform(scaleX: 1, y: 1)}
                        }
                        self?.pastChoice = choice
                })
            }).disposed(by: bag)
        }
        
        questionImage.margins = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
        questionImage.contentMode = .scaleAspectFit
        questionImage.addConstraint(NSLayoutConstraint(item: questionImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 200))
        
        imageStack.margins = UIEdgeInsets(top: 105.0, left: 20.0, bottom: 40.0, right: 20.0)
        imageStack.axis = .vertical
        imageStack.spacing = 10
        imageStack.isLayoutMarginsRelativeArrangement = true
        imageStack.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        imageStack.backgroundView.backgroundColor = .white
        imageStack.backgroundView.layer.masksToBounds = false
        imageStack.backgroundView.layer.shadowColor = UIColor.shadow.cgColor
        imageStack.backgroundView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        imageStack.backgroundView.layer.shadowOpacity = 1.0
        imageStack.backgroundView.layer.shadowRadius = 6.0
        imageStack.cornerRadius = 20
        imageStack.pinBackground(imageStack.backgroundView, to: imageStack)
        
        enlarge.image = UIImage(named: "icon040")
        let enlargeLogo = NSAttributedString(attachment: enlarge)
        let com = NSMutableAttributedString(string: "" )
        com.append(enlargeLogo)
        let text = NSAttributedString(string: "  กดรูปเพื่อขยาย", attributes:attrs)
        com.append(text)
        
        imageCaption.attributedText = com
        imageCaption.textAlignment = .right
        
        [questionImage, textQuestion, imageCaption].forEach { label in
            imageStack.addArrangedSubview(label)
        }
        
        viewModel.state.asObservable().bind(to: textQuestion.rx.isHidden).disposed(by: bag)
        viewModel.title.asObservable().bind(to: textQuestion.rx.title).disposed(by: bag)
        
        setupCardParts([imageStack, choice1, choice2, choice3, choice4, choice5])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgLayer.frame = view.bounds.inset(by: UIEdgeInsets(top: 100.0, left: 0.0, bottom: 0.0, right: 0.0))
    }

    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        
        let imageView = sender.view as! UIImageView
        let scrollView = UIScrollView()
        let newImageView = UIImageView(image: imageView.image)
        let window = self.view.window!
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissScreen))
        
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = true
        scrollView.flashScrollIndicators()
        scrollView.alpha = 0
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        scrollView.bounces = false
        scrollView.isUserInteractionEnabled = true
        scrollView.bouncesZoom = false
        scrollView.frame = window.bounds
        
        [scrollView, newImageView].forEach { view in
            
            view.translatesAutoresizingMaskIntoConstraints = true
            view.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin, UIView.AutoresizingMask.flexibleRightMargin, UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleBottomMargin, UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
        }
        
        newImageView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        newImageView.contentMode = .scaleAspectFit
        newImageView.frame = scrollView.bounds
        
        scrollView.insertSubview(newImageView, at: 0)
        scrollView.addGestureRecognizer(tap)
        
        window.addSubview(scrollView)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            
            scrollView.alpha = 1

        }, completion: nil)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        let boundsSize = scrollView.bounds.size
        var frameToCenter = scrollView.subviews.first!.frame

        let widthDiff = boundsSize.width  - frameToCenter.size.width
        let heightDiff = boundsSize.height - frameToCenter.size.height
        frameToCenter.origin.x = (widthDiff  > 0) ? widthDiff  / 2 : 0;
        frameToCenter.origin.y = (heightDiff > 0) ? heightDiff / 2 : 0;

        scrollView.subviews.first!.frame = frameToCenter;
    }
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first
    }
    
    @objc func dismissScreen(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {

            sender.view?.alpha = 0
            
        }, completion: {finished in
            
            sender.view?.removeFromSuperview()
            
        })
    }
}

