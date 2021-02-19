//
//  userViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 16/9/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts


class UserViewController: CardsViewController {
    
    var userController: UserViewCardController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cards: [CardController] = [userController]
        self.view.subviews.first?.backgroundColor = .clear
        view.addBackground()
        loadCards(cards: cards)
    }
}


class UserViewCardController: CardPartsViewController, TransparentCardTrait {
    
    var viewModel: UserViewModel!
    
    let userImage = CardPartImageView()
    let pointView = CardPartTextView(type: .normal)
    let performView = CardPartTextView(type: .normal)
    let incorrectView = CardPartTextView(type: .normal)
    let stackView = CardPartStackView()
    let stackViewEnd = CardPartStackView()
    let buttonPerson = CardPartButtonView()
    let resetButton = CardPartButtonView()
    let correctStack = CardPartStackView()
    let incorrectStack = CardPartStackView()
    let imageCorrect = CardPartImageView()
    let imageIncorrect = CardPartImageView()
    let correctText = CardPartTextView(type: .normal)
    let incorrectText = CardPartTextView(type: .normal)
    let badge = CardPartImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.username.asObservable().bind(to: buttonPerson.rx.buttonTitle).disposed(by: bag)
        viewModel.pointAll.asObservable().bind(to: pointView.rx.attributedText).disposed(by: bag)
        viewModel.correctAll.asObservable().bind(to: performView.rx.text).disposed(by: bag)
        viewModel.incorrectAll.asObservable().bind(to: incorrectView.rx.text).disposed(by: bag)

        userImage.image = UIImage(systemName: "person.crop.circle")
        userImage.addConstraint(NSLayoutConstraint(item: userImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 100))
        userImage.tintColor = .white
        userImage.contentMode = .scaleAspectFit

        buttonPerson.contentHorizontalAlignment = .center
        buttonPerson.titleLabel?.font = UIFont(name: "Baskerville-Bold", size: CGFloat(36))!
        
        buttonPerson.setImage(UIImage(systemName: "pencil"), for: .normal)
        buttonPerson.centerTextAndImage(spacing: 10)
        buttonPerson.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        buttonPerson.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPerson.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPerson.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPerson.imageView?.contentMode = .scaleAspectFill
        buttonPerson.imageView?.clipsToBounds = false
        buttonPerson.imageView?.tintColor = .black
        buttonPerson.margins = UIEdgeInsets(top: 10, left: 100, bottom: 10, right: 100)
        
        pointView.textAlignment = .center
        pointView.font = pointView.font.withSize(40)
        correctText.text = "Correct  Answer "
        incorrectText.text = "Incorrect Answer"
        correctText.textAlignment = .center
        incorrectText.textAlignment = .center
        performView.textColor = .correct
        incorrectView.textColor = .wrong
        performView.textAlignment = .center
        performView.font = UIFont(name: "Baskerville-Bold", size: CGFloat(50))!
        incorrectView.textAlignment = .center
        incorrectView.font = UIFont(name: "Baskerville-Bold", size: CGFloat(50))!
        
        resetButton.margins = UIEdgeInsets(top: 10, left: 200, bottom: 10, right: 50)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(16))!
        resetButton.setImage(UIImage(named: "icon050"), for: .normal)
        resetButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        resetButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        resetButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        resetButton.centerTextAndImage(spacing: 10)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        
        correctStack.axis = .vertical
        correctStack.spacing = 0
        correctStack.distribution = .equalSpacing
        correctStack.isLayoutMarginsRelativeArrangement = true
        correctStack.layoutMargins = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        correctStack.backgroundView.frame = CGRect(x: correctStack.frame.size.width - 2, y: 0, width: 2, height: correctStack.frame.size.height)
        correctStack.backgroundView.backgroundColor = .Gray6
        correctStack.backgroundView.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        correctStack.addSubview(correctStack.backgroundView)
        
        incorrectStack.axis = .vertical
        incorrectStack.spacing = 0
        incorrectStack.distribution = .equalSpacing
        incorrectStack.isLayoutMarginsRelativeArrangement = true
        incorrectStack.layoutMargins = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        imageCorrect.image = UIImage(named: "right0")
        imageIncorrect.image = UIImage(named: "wrong0")
        imageIncorrect.contentMode = .scaleAspectFit
        imageCorrect.contentMode = .scaleAspectFit
        
        imageCorrect.addConstraint(NSLayoutConstraint(item: imageCorrect, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 60))
        
        imageIncorrect.addConstraint(NSLayoutConstraint(item: imageIncorrect, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 60))
        
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        stackView.backgroundView.backgroundColor = .white
        stackView.cornerRadius = 30
        stackView.pinBackground(stackView.backgroundView, to: stackView)
        stackView.margins = UIEdgeInsets(top: 20, left: 25, bottom: 10, right: 25)
        badge.contentMode = .scaleAspectFit
        stackView.addSubview(badge)
        
        stackViewEnd.axis = .horizontal
        stackViewEnd.spacing = 10
        stackViewEnd.distribution = .fillEqually
        stackViewEnd.isLayoutMarginsRelativeArrangement = true
        stackViewEnd.layoutMargins = UIEdgeInsets(top: 10, left: 25, bottom: 10, right: 25)
        
        [imageCorrect, correctText, performView].forEach { label in
            correctStack.addArrangedSubview(label)}
            
        [imageIncorrect, incorrectText, incorrectView].forEach { label in
            incorrectStack.addArrangedSubview(label)}
        
        [correctStack, incorrectStack].forEach { label in
            stackViewEnd.addArrangedSubview(label)}
            
        [pointView, stackViewEnd].forEach { label in
                stackView.addArrangedSubview(label)
        }
        
        viewModel.picGrade.asObservable().bind(to: badge.rx.image).disposed(by: bag)
        
        setupCardParts([userImage, buttonPerson, stackView, resetButton])
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshData()
        viewModel.getResult()
        
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.centerXAnchor.constraint(equalTo: stackView.centerXAnchor, constant: -110).isActive = true
        badge.centerYAnchor.constraint(equalTo: stackView.centerYAnchor, constant: -150).isActive = true
        badge.widthAnchor.constraint(equalToConstant: 100).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    
    @objc func buttonTapped() {
        
        let alertController = UIAlertController(title: "User Setting", message: "Set Username", preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler:  { [weak alertController] (action) -> Void in
            
            let textField = alertController?.textFields![0]
            
            if !textField!.text!.isEmpty {
                self.viewModel.setUsername(nameIn: (textField?.text)!) }
        })
        
        alertController.addAction(confirmAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler:  {  (action) -> Void in
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func resetTapped() {
        
        let alertController = UIAlertController(title: "Reset", message: "Are you sure?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler:  {  (action) -> Void in
                self.viewModel.resetData()
                self.viewModel.refreshData()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler:  {  (action) -> Void in
        }))
        
        
        self.present(alertController, animated: true, completion: nil)
    }
}

