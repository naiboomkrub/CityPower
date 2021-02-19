//
//  QuizTemViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 15/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import RxDataSources


class QuizTemViewController: CardsViewController {
    
    var viewModel: QuizTemViewModel!
    var quizSelectViewController: QuizSelectViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setTopic()
        let cards: [CardController] = [quizSelectViewController]
        loadCards(cards: cards)
    }
}


class QuizSelectViewController: CardPartsViewController,  CardPartCollectionViewDelegte {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let currentCell = collectionView.cellForItem(at: indexPath) as? SelectCell else { return }
        
        currentCell.backgroundColor = .lightBlueCity
        viewModel.quizSelected.accept(currentCell.quizTitle.text!)
        currentCell.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            UIView.animate(withDuration: 0.2, animations: {
                currentCell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                }, completion: { [weak self] _ in
                    if self?.pastCell != nil && self?.pastCell != currentCell {
                        UIView.animate(withDuration: 0.1) {
                            self?.pastCell.backgroundColor = .general
                            self?.pastCell.transform = CGAffineTransform(scaleX: 1, y: 1)}
                    }
                self?.pastCell = currentCell
            })
    }
    
    var viewModel: QuizTemViewModel!
    var pastCell: SelectCell!
    
    let buttonPart = CardPartButtonView()
    let startButton = CardPartStackView()
    let quizTitle = CardPartTextView(type: .normal)
    
    let gradientLayerStart = CAGradientLayer()
    let borderLayerStart = UIView()
    
    lazy var selectedCollection = CardPartCollectionView(collectionViewLayout: collectionViewLayout)
    var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.scrollDirection = .vertical
        
        let noOfCellsInRow = 2

        let totalSpace = layout.sectionInset.left
            + layout.sectionInset.right
            + (layout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((UIScreen.main.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        layout.itemSize = CGSize(width: size - 40, height: size - 40)
        return layout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        startButton.margins = UIEdgeInsets(top: 10, left: 100, bottom: 30, right: 100)
        
        quizTitle.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
        quizTitle.margins = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        
        selectedCollection.margins =  UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        selectedCollection.delegate = self
        selectedCollection.collectionView.clipsToBounds = false
        selectedCollection.collectionView.backgroundColor = .clear
        selectedCollection.collectionView.register(SelectCell.self, forCellWithReuseIdentifier: "SelectCell")
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfSelectStruct>(configureCell: { (_, collectionView, indexPath, data) -> UICollectionViewCell in

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectCell", for: indexPath) as? SelectCell else { return UICollectionViewCell() }

            cell.setData(data)
            cell.backgroundColor = .general
            cell.layer.cornerRadius = 20

            return cell
        })
        
        viewModel.data.asObservable().bind(to: selectedCollection.collectionView.rx.items(dataSource: dataSource)).disposed(by: bag)
        
        selectedCollection.collectionView.frame = CGRect(x: 0, y: 0, width: collectionViewLayout.itemSize.width * 2 + 12, height: collectionViewLayout.itemSize.height * 2 + 20)
        
        viewModel.quizTitle.asObservable().bind(to: quizTitle.rx.text).disposed(by: bag)
        buttonPart.rx.tap.bind(onNext: viewModel.choseTopic).disposed(by: bag)
        
        setupCardParts([quizTitle, selectedCollection, startButton])

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.gradientLayerStart.frame = self.startButton.bounds
        self.borderLayerStart.frame = self.startButton.bounds

    }
}


class SelectCell: CardPartCollectionViewCardPartsCell {
    
    let bag = DisposeBag()

    let quizStack = CardPartStackView()
    let quizTitle = CardPartTextView(type: .normal)
    let quizDes = CardPartTextView(type: .title)

    override init(frame: CGRect) {

        super.init(frame: frame)

        quizStack.axis = .vertical
        quizStack.alignment = .center
        quizStack.spacing = 10
        quizStack.isLayoutMarginsRelativeArrangement = true
        quizStack.layoutMargins = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        
        quizDes.textColor = .white
        
        quizStack.addArrangedSubview(quizTitle)
        quizStack.addArrangedSubview(quizDes)

        setupCardParts([quizStack])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(_ data: SelectStruct) {

        quizTitle.text = data.title
        quizDes.text = data.description
    }
}

