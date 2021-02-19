//
//  QuizResultController.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 27/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxDataSources
import RxSwift
import RxCocoa

class QuizResultController: CardsViewController {
    
    var resultController: ResultController!
    var endController: EndController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.subviews.first?.backgroundColor = .clear
        view.addBackground()
        
        let cards: [CardController] = [resultController, endController]
           
        loadCards(cards: cards)
    }
}

class ResultController: CardPartsViewController, TransparentCardTrait {
    
    var viewModel: QuizResultViewModel!
    
    let titlePart1 = CardPartTextView(type: .normal)
    let nameView = CardPartTitleView(type: .titleOnly)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameView.label.textAlignment = .center
        nameView.label.textColor = .white
        
        titlePart1.textAlignment = .center
        titlePart1.text = "ได้คะแนน"
        titlePart1.margins =  UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            
        viewModel.name.asObservable().bind(to: nameView.rx.title).disposed(by: bag)
        
        setupCardParts([nameView,titlePart1])
    }
}


class EndController: CardPartsViewController, TransparentCardTrait, CustomMarginCardTrait, CardPartCollectionViewDelegte {
    
    func customMargin() -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
               
        let viewController = GameSession.shared.mGameController[indexPath.row]
        viewController.view.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissScreen))
        let window = self.view.window!
        viewController.view.frame = window.frame
        viewController.view.backgroundColor = .blueCity
        viewController.view.addGestureRecognizer(tap)
        window.addSubview(viewController.view)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            
            viewController.view.alpha = 1

        }, completion: nil)
    }
    
    var viewModel: QuizResultViewModel!
    
    let resultStack = CardPartStackView()
    let explainStack = CardPartStackView()
    let subStack = CardPartStackView()
    let buttonPart = CardPartButtonView()
    let crownImage = CardPartImageView()
    let pencilImage = CardPartImageView()
    let review = CardPartTitleView(type: .titleOnly)
    let explain = CardPartTextView(type: .title)
    let resultCenter = CardPartImageView()
    
    let gradient = CAGradientLayer()
    let border = UIView()
    
    let num1 = UILabel()
    let num2 = UILabel()
    let badge = UIImageView()
    
    lazy var collectionViewCardPart = CardPartCollectionView(collectionViewLayout: self.collectionViewLayout)
    var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 7
        layout.minimumLineSpacing = 12
        layout.itemSize = CGSize(width: 45, height: 45)
        layout.sectionInset.right = 15
        
        return layout
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        resultCenter.margins = UIEdgeInsets(top: -50, left: 0, bottom: 0, right: 0)
        resultCenter.image = UIImage(named: "score0")
        resultCenter.contentMode = .scaleAspectFit
        resultCenter.clipsToBounds = true
        resultCenter.addConstraint(NSLayoutConstraint(item: resultCenter, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 300))
        
        num1.textAlignment = .center
        num2.textAlignment = .center
        num1.textColor = .white
        num2.textColor = .blueCity
        num1.font = UIFont(name: "Baskerville-Bold", size: CGFloat(80))
        num2.font = UIFont(name: "Baskerville-Bold", size: CGFloat(44))
        badge.contentMode = .scaleAspectFit
        resultCenter.addSubview(num1)
        resultCenter.addSubview(num2)
        resultCenter.addSubview(badge)
        
        crownImage.image = UIImage(named: "crown0")
        pencilImage.image = UIImage(named: "pencil0")
        review.title = "Review"
        review.label.textAlignment = .center
        explain.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
        explain.text = "กดดูข้อที่ทำไปแล้ว"
        explain.textAlignment = .center
        
        crownImage.contentMode = .scaleAspectFit
        crownImage.addConstraint(NSLayoutConstraint(item: crownImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50))
        crownImage.addConstraint(NSLayoutConstraint(item: crownImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50))
        
        pencilImage.contentMode = .scaleAspectFit
        pencilImage.addConstraint(NSLayoutConstraint(item: pencilImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50))
        pencilImage.addConstraint(NSLayoutConstraint(item: pencilImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50))
  
        subStack.axis = .vertical
        subStack.spacing = 0
        subStack.distribution = .equalSpacing
    
        explainStack.isLayoutMarginsRelativeArrangement = true
        explainStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        explainStack.axis = .horizontal
        explainStack.spacing = 5
        explainStack.distribution = .equalSpacing
        
        [review, explain].forEach { label in
            subStack.addArrangedSubview(label)}
        [crownImage, subStack, pencilImage].forEach { label in
            explainStack.addArrangedSubview(label)}

        resultStack.axis = .vertical
        resultStack.spacing = 30
        resultStack.distribution = .equalSpacing
        resultStack.isLayoutMarginsRelativeArrangement = true
        resultStack.layoutMargins = UIEdgeInsets(top: 40, left: 20, bottom: 20, right: 20)
        resultStack.backgroundView.backgroundColor = .white
        resultStack.cornerRadius = 20
        resultStack.pinBackground(resultStack.backgroundView, to: resultStack)
        
        buttonPart.margins = UIEdgeInsets(top: 20, left: 80, bottom: 20, right: 80)
        buttonPart.setTitle("Try again", for: .normal)
        buttonPart.setTitleColor(.white, for: .normal)
        buttonPart.contentHorizontalAlignment = .center
        buttonPart.layer.shadowColor = UIColor.black.cgColor
        buttonPart.layer.shadowRadius = 3.0
        buttonPart.layer.shadowOpacity = 0.4
        buttonPart.layer.shadowOffset = CGSize(width: 4, height: 4)
        border.layer.cornerRadius = 25
        border.layer.masksToBounds = true
        
        let colorTop =  UIColor.start1.cgColor
        let colorBottom = UIColor.start2.cgColor
        gradient.colors = [colorTop, colorBottom]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        border.layer.insertSublayer(gradient, at: 0)
        
        buttonPart.setImage(UIImage(named: "icon010"), for: .normal)
        buttonPart.centerTextAndImage(spacing: 10)
        buttonPart.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        buttonPart.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPart.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        buttonPart.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        border.isUserInteractionEnabled = false
        buttonPart.insertSubview(border, at: 0)
        
        collectionViewCardPart.delegate = self
        collectionViewCardPart.collectionView.register(quizViewCell.self, forCellWithReuseIdentifier: "quizCell")
        collectionViewCardPart.collectionView.backgroundColor = .clear
        collectionViewCardPart.collectionView.showsHorizontalScrollIndicator = false

        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfCustomStruct>(configureCell: { (_, collectionView, indexPath, data) -> UICollectionViewCell in
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "quizCell", for: indexPath) as? quizViewCell else { return UICollectionViewCell() }

            cell.setData(data)
            cell.backgroundColor = data.color ? .correct : .wrong
            cell.layer.cornerRadius = cell.frame.size.width / 2.0
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowRadius = 3.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.shadowOffset = CGSize(width: 4, height: 4)
            cell.layer.masksToBounds = false
            
            return cell
        })
        
        viewModel.data.asObservable().bind(to: collectionViewCardPart.collectionView.rx.items(dataSource: dataSource)).disposed(by: bag)
        viewModel.title2.asObservable().bind(to: num2.rx.text).disposed(by: bag)
        viewModel.title1.asObservable().bind(to: badge.rx.image).disposed(by: bag)
        viewModel.score.asObservable().bind(to: num1.rx.text).disposed(by: bag)
        buttonPart.rx.tap.bind(onNext: viewModel.quit).disposed(by: bag)
        
        collectionViewCardPart.collectionView.frame = CGRect(x: 0, y: 0, width: 120 , height: 120)
        
        [explainStack, collectionViewCardPart].forEach { label in
            resultStack.addArrangedSubview(label)}
        
        resultStack.margins.top = -90
        
        setupCardParts([resultCenter, resultStack, buttonPart])
        view.bringSubviewToFront(resultCenter)
    }
    
    @objc func dismissScreen(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {

            sender.view?.alpha = 0
            
        }, completion: {finished in
            
            sender.view?.removeFromSuperview()
            
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        gradient.frame = buttonPart.bounds
        border.frame = buttonPart.bounds
        
        num1.translatesAutoresizingMaskIntoConstraints = false
        num1.centerXAnchor.constraint(equalTo: resultCenter.centerXAnchor, constant: -35).isActive = true
        num1.centerYAnchor.constraint(equalTo: resultCenter.centerYAnchor, constant: -5).isActive = true
            
        num2.translatesAutoresizingMaskIntoConstraints = false
        num2.centerXAnchor.constraint(equalTo: resultCenter.centerXAnchor, constant: 20).isActive = true
        num2.centerYAnchor.constraint(equalTo: resultCenter.centerYAnchor, constant: 40).isActive = true
        
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.centerXAnchor.constraint(equalTo: resultCenter.centerXAnchor, constant: 40).isActive = true
        badge.centerYAnchor.constraint(equalTo: resultCenter.centerYAnchor, constant: -40).isActive = true
        badge.widthAnchor.constraint(equalToConstant: 100).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradient.frame = buttonPart.bounds
        border.frame = buttonPart.bounds
    }
}


class quizViewCell: CardPartCollectionViewCardPartsCell {
    
    let bag = DisposeBag()
    
    let titleCP = CardPartTextView(type: .normal)
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
       
        titleCP.margins = .init(top: 4, left: 0, bottom: 0, right: 0)
        setupCardParts([titleCP])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(_ data: DataCell) {
        
        titleCP.text = data.index
        titleCP.textAlignment = .center
        titleCP.textColor = .white
    }
}

extension UIView {
    func addBackground() {
    
        let imageViewBackground = UIImageView(frame: UIScreen.main.bounds)
        imageViewBackground.image = UIImage(named: "blue-bg0")

        imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill

        addSubview(imageViewBackground)
        sendSubviewToBack(imageViewBackground)
    
        imageViewBackground.translatesAutoresizingMaskIntoConstraints = false
    
        let leadingConstraint = NSLayoutConstraint(item: imageViewBackground, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailingConstraint = NSLayoutConstraint(item: imageViewBackground, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let topConstraint = NSLayoutConstraint(item: imageViewBackground, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let bottomConstraint = NSLayoutConstraint(item: imageViewBackground, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)

        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    
}}
