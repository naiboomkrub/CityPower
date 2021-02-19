//
//  AllQuizViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import RxDataSources


class AllQuizViewController: CardsViewController {
    
    var viewModel: AllQuizViewModel!
    var quizButtonController: QuizButtonController!
    var quizListController: QuizListController!
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cards: [CardController] = [quizButtonController, quizListController]
        viewModel.setTopic()
        loadCards(cards: cards)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
}


class QuizButtonController: CardPartsViewController {
    
    var viewModel: AllQuizViewModel!
    
    let welcomeView = CardPartTextView(type: .normal)
    let allStack = CardPartStackView()
    let overView = CardPartTextView(type: .normal)
    let incorrectView = CardPartTextView(type: .normal)
    let totalQuiz = CardPartTextView(type: .normal)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeView.text = "Overview"
        welcomeView.margins = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 0)
        welcomeView.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(36))!
        
        allStack.margins = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        allStack.axis = .vertical
        allStack.spacing = 10
        allStack.isLayoutMarginsRelativeArrangement = true
        allStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        allStack.backgroundView.backgroundColor = .whiteCity
        allStack.pinBackground(allStack.backgroundView, to: allStack)
        
        [overView, incorrectView, totalQuiz].forEach { label in
            allStack.addArrangedSubview(label)}
        
        overView.text = "Total Correct Answer : 100"
        incorrectView.text = "Total Incorrect Answer : 100"
        totalQuiz.text = "Total Quiz : 100"
        
        setupCardParts([welcomeView, allStack])
    }
}


class QuizListController: CardPartsViewController, TransparentCardTrait, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let currentCell = collectionView.cellForItem(at: indexPath) as? QuizCell else { return }
        if currentCell.quizTitle.text == "KorWor" {
            viewModel.startQuiz()
        } else {
            viewModel.startNormalQuiz(selectQuiz: currentCell.quizTitle.text!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 || indexPath.row == 3 {
            return CGSize(width:  collectionView.frame.width, height: 120)
        } else {
            return CGSize(width: size - 40, height: size - 40)
        }
    }
    
    var viewModel: AllQuizViewModel!
    var size: CGFloat!
    
    let quizList = CardPartTextView(type: .normal)
    
    lazy var quizCollection = CardPartCollectionView(collectionViewLayout: collectionLayout)
    var collectionLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 12
        layout.scrollDirection = .vertical
        
        return layout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let noOfCellsInRow = 2
        let totalSpace = collectionLayout.sectionInset.left
            + collectionLayout.sectionInset.right
            + (collectionLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        self.size = CGFloat((UIScreen.main.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        quizList.text = "Quiz List"
        quizList.margins = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 0)
        quizList.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(26))!
        
        quizCollection.margins =  UIEdgeInsets(top: 20, left: 30, bottom: 0, right: 30)
        quizCollection.collectionView.clipsToBounds = false
        quizCollection.collectionView.delegate = nil
        quizCollection.collectionView.rx.setDelegate(self).disposed(by: bag)
        
        quizCollection.collectionView.backgroundColor = .clear
        quizCollection.collectionView.register(QuizCell.self, forCellWithReuseIdentifier: "QuizCell")
        quizCollection.collectionView.register(SqaureCell.self, forCellWithReuseIdentifier: "SqaureCell")
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfQuizStruct>(configureCell: { (_, collectionView, indexPath, data) -> UICollectionViewCell in
    
            if indexPath.row == 0 || indexPath.row == 3 {
                                
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuizCell", for: indexPath) as? QuizCell else { return UICollectionViewCell() }
                
                cell.setData(data)
                
                switch cell.quizTitle.text {
                case "General":
                    cell.gradientLayer.colors =  [UIColor.start1.cgColor, UIColor.start2.cgColor]
                case "KorWor":
                    cell.gradientLayer.colors =  [UIColor.sanitary.cgColor, UIColor.sanitary2.cgColor]
                default:
                    cell.gradientLayer.colors =  [UIColor.general.cgColor, UIColor.general2.cgColor]
                }
                
                return cell
              
            } else {
            
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SqaureCell", for: indexPath) as? SqaureCell else { return UICollectionViewCell() }
                
                cell.setData(data)
                
                switch cell.quizTitle.text {
                case "General":
                    cell.gradientLayer.colors =  [UIColor.start1.cgColor, UIColor.start2.cgColor]
                case "KorWor":
                    cell.gradientLayer.colors =  [UIColor.sanitary.cgColor, UIColor.sanitary2.cgColor]
                default:
                    cell.gradientLayer.colors =  [UIColor.general.cgColor, UIColor.general2.cgColor]
                }
                
                return cell
            }
        })
        
        viewModel.data.asObservable().bind(to: quizCollection.collectionView.rx.items(dataSource: dataSource)).disposed(by: bag)
        
        quizCollection.collectionView.frame = CGRect(x: 0, y: 0, width: collectionLayout.itemSize.width * 2 + 12, height: (self.size - 40) * 2 + 20 + 140)
        
        setupCardParts([quizList, quizCollection])
    }
}


class QuizCell: CardPartCollectionViewCardPartsCell {
    
    let quizStack = CardPartStackView()
    let quizTitle = CardPartTextView(type: .normal)
    let quizDes = CardPartTextView(type: .title)
    
    let gradientLayer = CAGradientLayer()
    let borderLayer = UIView()
    
    override init(frame: CGRect) {

        super.init(frame: frame)

        quizStack.axis = .vertical
        quizStack.alignment = .center
        quizStack.spacing = 5
        
        quizTitle.textColor = .white
        quizDes.textColor = .white
        quizStack.addArrangedSubview(quizTitle)
        quizStack.addArrangedSubview(quizDes)
        
        setupCardParts([quizStack])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        borderLayer.frame = contentView.bounds
    }

    func setData(_ data: QuizStruct) {

        quizTitle.text = data.title
        quizDes.text = data.description
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 3, height: 3)
        contentView.layer.shadowOpacity = 0.3
        contentView.layer.shadowRadius = 4.0
        
        borderLayer.layer.cornerRadius = 10.0
        borderLayer.layer.masksToBounds = true
        borderLayer.layer.insertSublayer(gradientLayer, at: 0)
        
        contentView.addSubview(borderLayer)
        contentView.sendSubviewToBack(borderLayer)
    }
}


class SqaureCell: CardPartCollectionViewCardPartsCell {
    
    let quizStack = CardPartStackView()
    let quizStack2 = CardPartStackView()
    let quizTitle = CardPartTextView(type: .normal)
    let quizDes = CardPartTextView(type: .title)
    let quizDes2 = CardPartTextView(type: .title)
    
    let gradientLayer = CAGradientLayer()
    let borderLayer = UIView()
    
    override init(frame: CGRect) {

        super.init(frame: frame)

        quizStack.axis = .vertical
        quizStack.alignment = .center
        quizStack.spacing = 15
        
        quizStack2.axis = .vertical
        quizStack2.alignment = .center
        quizStack2.spacing = 0
        
        quizTitle.textColor = .white
        quizDes.textColor = .white
        quizDes.font = quizDes.font.withSize(16)
      //  quizStack2.widthAnchor.constraint(equalToConstant: frame.width).isActive = true
        quizDes.textAlignment = .center
        
        quizDes2.font = quizDes.font.withSize(16)
        quizDes2.textAlignment = .center
        quizDes2.textColor = .white
        
        quizStack2.addArrangedSubview(quizDes)
        quizStack2.addArrangedSubview(quizDes2)
        
        quizStack.addArrangedSubview(quizTitle)
        quizStack.addArrangedSubview(quizStack2)
        
        quizStack2.isLayoutMarginsRelativeArrangement = true
        quizStack2.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        quizStack2.backgroundView.backgroundColor = .general2
        quizStack2.pinBackground(quizStack2.backgroundView, to: quizStack2)
        
        setupCardParts([quizStack])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        borderLayer.frame = contentView.bounds
    }

    func setData(_ data: QuizStruct) {

        quizTitle.text = data.title
        quizDes.text = data.description
        quizDes2.text = "Topic Number: \(data.number)"
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 3, height: 3)
        contentView.layer.shadowOpacity = 0.3
        contentView.layer.shadowRadius = 4.0
        
        borderLayer.layer.cornerRadius = 10.0
        borderLayer.layer.masksToBounds = true
        borderLayer.layer.insertSublayer(gradientLayer, at: 0)
        
        contentView.addSubview(borderLayer)
        contentView.sendSubviewToBack(borderLayer)
    }
}
