//
//  KnowledgeMenuViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift


class KnowledgeMenuViewController: CardsViewController {
    
    var viewModel: KnowledgeMenuViewModel!
    var knowledgeMenuController: KnowledgeMenuController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let cards: [CardController] =  [knowledgeMenuController]
        
        loadCards(cards: cards)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}


class KnowledgeMenuController: CardPartsViewController {
        
    var viewModel: KnowledgeMenuViewModel!
    
    let menuDes = CardPartTextView(type: .normal)
    let lessonButton = CardPartButtonView()
    let quizButton = CardPartButtonView()
    let videoButton = CardPartButtonView()
    let lessonStack = CardPartStackView()
    let quizStack = CardPartStackView()
    let videoStack = CardPartStackView()
    
    let lessonLayer = CAGradientLayer()
    let lessonBorder = UIView()
    let quizLayer = CAGradientLayer()
    let quizBorder = UIView()
    let videoLayer = CAGradientLayer()
    let videoBorder = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuDes.text = "Please Choose The option"
        menuDes.margins = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20)
        menuDes.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
        
        setUpButton(lessonButton, "Lesson", UIColor.white, "icon020", lessonStack, [UIColor.start1, UIColor.start2], lessonLayer, lessonBorder)
        setUpButton(quizButton, "Quiz", UIColor.white, "icon020", quizStack, [UIColor.start1, UIColor.start2], quizLayer, quizBorder)
        setUpButton(videoButton, "Video", UIColor.white, "icon020", videoStack, [UIColor.start1, UIColor.start2], videoLayer, videoBorder)
        
        lessonButton.rx.tap.bind(onNext: viewModel.startLesson).disposed(by: bag)
        quizButton.rx.tap.bind(onNext: viewModel.startQuiz).disposed(by: bag)
        
        setupCardParts([menuDes, lessonStack, quizStack, videoStack])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stretchButton()
    }
}

extension KnowledgeMenuController {
    
    func setUpButton(_ buttonPart: CardPartButtonView, _ text: String, _ color: UIColor, _ icon: String, _ stackView: CardPartStackView, _ colours: [UIColor], _ gradient: CAGradientLayer, _ borderView: UIView) {
        
        buttonPart.setTitle(text, for: .normal)
        buttonPart.setTitleColor(color, for: .normal)
        buttonPart.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        buttonPart.setImage(UIImage(named: icon), for: .normal)
        buttonPart.centerTextAndImage(spacing: 20)
        buttonPart.contentHorizontalAlignment = .center
        buttonPart.contentEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        buttonPart.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPart.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPart.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        
        setGradient(stack: stackView, colours: colours, gradient: gradient, borderView: borderView, radius: 0)
        stackView.pinBackground(stackView.backgroundView, to: stackView)
        stackView.addArrangedSubview(buttonPart)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
        stackView.margins = UIEdgeInsets(top: 20, left: 60, bottom: 30, right: 60)
    }
    
    func stretchButton() {
        self.lessonLayer.frame = self.lessonStack.bounds
        self.lessonBorder.frame = self.lessonStack.bounds
        self.quizLayer.frame = self.quizStack.bounds
        self.quizBorder.frame = self.quizStack.bounds
        self.videoLayer.frame = self.videoStack.bounds
        self.videoBorder.frame = self.videoStack.bounds
    }
}
