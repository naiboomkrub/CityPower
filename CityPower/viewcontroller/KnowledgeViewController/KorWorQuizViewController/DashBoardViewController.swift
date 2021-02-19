//
//  GameViewController.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 24/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import CardParts
import RxCocoa
import RxSwift


class DashBoardViewController: CardsViewController {
    
    @IBOutlet weak var menuNavigation: UINavigationItem!
    
    var contentCardController: ContentCardController!
    var viewModel: DashBoardViewModel!
    
    let button = UIBarButtonItem()
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cards: [CardController] = [contentCardController]
        let button = UIBarButtonItem(image: UIImage(systemName: "person.circle")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: nil)
        menuNavigation.rightBarButtonItem = button
        button.rx.tap.bind(onNext: viewModel.user).disposed(by: disposeBag)
 
        let logo = UIButton()
        logo.setBackgroundImage(UIImage(named: "Asset 20"), for: .normal)
        
        loadCards(cards: cards)

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        view.subviews.first?.backgroundColor = .white
        
        let logoTop = UIBarButtonItem(customView: logo)
        let currWidth = logoTop.customView?.widthAnchor.constraint(equalToConstant: 27)
        currWidth?.isActive = true
        let currHeight = logoTop.customView?.heightAnchor.constraint(equalToConstant: 27)
        currHeight?.isActive = true
        
        logo.rx.tap.bind(onNext: viewModel.exit).disposed(by: disposeBag)
        menuNavigation.leftBarButtonItem = logoTop
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.blueCity]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .blueCity
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
}


class ContentCardController: CardPartsViewController, TransparentCardTrait, UITextFieldDelegate {
    
    var viewModel: DashBoardViewModel!
    
    let logoCenter = CardPartImageView()
    let amountPart = CardPartTextField(format: .none)
    let stackView = CardPartStackView()
    let selectTopic = CardPartStackView()
    let numImage = CardPartImageView()
    let choiceNum = CardPartStackView()
    let categorySelect = CardPartButtonView()
    let buttonPart = CardPartButtonView()
    let titlePart = CardPartTitleView(type: .titleOnly)
    let titlePart2 = CardPartTitleView(type: .titleOnly)
    let textPart = CardPartTextView(type: .title)
    let mainStack = CardPartStackView()
    let startButton = CardPartStackView()
    
    let gradientLayer = CAGradientLayer()
    let gradientLayerStart = CAGradientLayer()
    
    let borderLayer = UIView()
    let borderLayerStart = UIView()
    let spaceIcon = UIView()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()
        
        logoCenter.imageName = "main-logo0"
        logoCenter.contentMode = .scaleAspectFit
        logoCenter.addConstraint(NSLayoutConstraint(item: logoCenter, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 150))

        titlePart.label.textAlignment = .center
        titlePart2.label.textAlignment = .center
        titlePart.label.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(30))!
        titlePart2.label.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(30))!
        textPart.textAlignment = .center
        
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.distribution = .equalSpacing
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        mainStack.backgroundView.layer.contents = #imageLiteral(resourceName: "main bg0").cgImage
        mainStack.pinBackground(mainStack.backgroundView, to: mainStack)
                        
        amountPart.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        amountPart.keyboardType = .numberPad
        amountPart.placeholder = "เลือกจำนวนหัวข้อ"
        amountPart.textColor = .blueCity
        amountPart.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        amountPart.delegate = self
        
        numImage.imageName = "Asset 50"
        numImage.contentMode = .scaleAspectFit
        spaceIcon.addSubview(numImage)
        spaceIcon.addConstraint(NSLayoutConstraint(item: spaceIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50))
        
        amountPart.leftViewMode = UITextField.ViewMode.always
        amountPart.leftView = spaceIcon
        
        choiceNum.isLayoutMarginsRelativeArrangement = true
        choiceNum.layoutMargins = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
        choiceNum.cornerRadius = 10.0
        choiceNum.backgroundView.backgroundColor = .white
        choiceNum.backgroundView.layer.shadowColor = UIColor.black.cgColor
        choiceNum.backgroundView.layer.shadowOffset = CGSize(width: 3, height: 3)
        choiceNum.backgroundView.layer.shadowOpacity = 0.5
        choiceNum.backgroundView.layer.shadowRadius = 4.0
        choiceNum.backgroundView.layer.masksToBounds = false
        choiceNum.backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: amountPart, action: #selector(amountPart.becomeFirstResponder)))
        choiceNum.pinBackground(choiceNum.backgroundView, to: choiceNum)
        
        [amountPart].forEach { label in
            choiceNum.addArrangedSubview(label)}
        
        buttonPart.setTitle("Start", for: .normal)
        buttonPart.setTitleColor(.white, for: .normal)
        buttonPart.setImage(UIImage(named: "icon020"), for: .normal)
        buttonPart.centerTextAndImage(spacing: 20)
        buttonPart.contentHorizontalAlignment = .center
        buttonPart.contentEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        buttonPart.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPart.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPart.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        
        setGradient(stack: startButton, colours: [.start1, .start2], gradient: gradientLayerStart, borderView: borderLayerStart, radius: 30)
        startButton.pinBackground(startButton.backgroundView, to: startButton)
        startButton.addArrangedSubview(buttonPart)
        
        categorySelect.setImage(UIImage(named: "Asset 40"), for: .normal)
        categorySelect.centerTextAndImage(spacing: 20)
        categorySelect.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        categorySelect.contentHorizontalAlignment = .left
        categorySelect.setTitleColor(UIColor.blueCity, for: .normal)
        categorySelect.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 20)
        
        selectTopic.cornerRadius = 10.0
        setGradient(stack: selectTopic, colours: [.white, .white], gradient: gradientLayer, borderView: borderLayer, radius: 10)
        selectTopic.pinBackground(selectTopic.backgroundView, to: selectTopic)
        selectTopic.addArrangedSubview(categorySelect)
        
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 30, left: 30, bottom: 20, right: 30)
        
        [selectTopic,choiceNum].forEach { label in
            stackView.addArrangedSubview(label)}
        
        stackView.addArrangedSubview(startButton, withMargin: UIEdgeInsets(top: 10, left: 50, bottom: -10, right: -50))
        
        [logoCenter, titlePart, titlePart2, textPart, stackView].forEach {label in
            mainStack.addArrangedSubview(label)}

        viewModel.colorGrad.asObservable().subscribe (onNext: { [weak self] color in
            self?.gradientLayer.colors = color.map {$0.cgColor}
        }).disposed(by: bag)
        
        viewModel.selectTopic.asObservable().bind(to: categorySelect.rx.buttonTitle).disposed(by: bag)
        viewModel.title.asObservable().bind(to: titlePart.rx.title).disposed(by: bag)
        viewModel.title2.asObservable().bind(to: titlePart2.rx.title).disposed(by: bag)
        viewModel.text.asObservable().bind(to: textPart.rx.text).disposed(by: bag)
            
        viewModel.choiceNum.map {if $0 != 0 { return String($0) } else { return "" }}
            .asObservable().bind(to: amountPart.rx.text).disposed(by: bag)
        categorySelect.rx.tap.bind(onNext: viewModel.select).disposed(by: bag)
        buttonPart.rx.tap.bind(onNext: viewModel.submit).disposed(by: bag)
        
        amountPart.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let textInt: Int = Int(self.amountPart.text!) {
                self.viewModel.changeNum(num: textInt)}
            }).disposed(by: bag)

        setupCardParts([mainStack])
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.gradientLayer.frame = self.selectTopic.bounds
        self.gradientLayerStart.frame = self.startButton.bounds
        self.borderLayer.frame = self.selectTopic.bounds
        self.borderLayerStart.frame = self.startButton.bounds
         
        numImage.translatesAutoresizingMaskIntoConstraints = false
        numImage.addConstraint(NSLayoutConstraint(item: numImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 28))
        amountPart.addConstraint(NSLayoutConstraint(item: amountPart, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 28))
    }
}

extension UIButton {
    func centerTextAndImage(spacing: CGFloat) {
        let insetAmount = spacing / 2
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: insetAmount)
    }
}

extension UIViewController {
    
    func setupHideKeyboardOnTap() {
        self.view.addGestureRecognizer(self.endEditingRecognizer())
        self.navigationController?.navigationBar.addGestureRecognizer(self.endEditingRecognizer())
    }

    private func endEditingRecognizer() -> UIGestureRecognizer {
        let tapFin = UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:)))
        tapFin.cancelsTouchesInView = false
        return tapFin
    }
}

