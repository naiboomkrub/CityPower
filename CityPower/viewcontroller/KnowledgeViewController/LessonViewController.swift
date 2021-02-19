//
//  LessonViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import RxDataSources


class LessonViewController: CardsViewController {
    
    var viewModel: LessonViewModel!
    var lessonTextController: LessonTextController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cards: [CardController] = [lessonTextController]
        viewModel.setTopic()
        loadCards(cards: cards)
    }
}

class LessonTextController: CardPartsViewController, CardPartCollectionViewDelegte {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      
        guard let currentCell = collectionView.cellForItem(at: indexPath) as? LessonCell else { return }
        viewModel.choseTopic(currentCell.lessonTitle.text!)
    }
    
    var viewModel: LessonViewModel!
    
    let lessonView = CardPartTextView(type: .normal)
    let lessonStack = CardPartStackView()

    lazy var lessonCollection = CardPartCollectionView(collectionViewLayout: collectionViewLayout)
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
        
        lessonView.text = "Engineering Knowledge"
        lessonView.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
        
        lessonStack.axis = .vertical
        lessonStack.spacing = 25
        lessonStack.distribution = .equalSpacing
        lessonStack.isLayoutMarginsRelativeArrangement = true
        lessonStack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
        lessonStack.pinBackground(lessonStack.backgroundView, to: lessonStack)
        
        lessonCollection.delegate = self
        lessonCollection.collectionView.backgroundColor = .clear
        lessonCollection.collectionView.register(LessonCell.self, forCellWithReuseIdentifier: "LessonCell")
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfLessonStruct>(configureCell: { (_, collectionView, indexPath, data) -> UICollectionViewCell in

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LessonCell", for: indexPath) as? LessonCell else { return UICollectionViewCell() }

            cell.setData(data)
            cell.layer.cornerRadius = 20
            
            switch cell.lessonTitle.text {
            case "General":
                cell.backgroundColor = UIColor.general
            case "Mechanic":
                cell.backgroundColor = UIColor.mechincal
            case "Electrical":
                cell.backgroundColor = UIColor.electrical
            case "Sanitary":
                cell.backgroundColor = UIColor.sanitary
            default:
                cell.backgroundColor = UIColor.general
            }

            return cell
        })
        
        viewModel.data.asObservable().bind(to: lessonCollection.collectionView.rx.items(dataSource: dataSource)).disposed(by: bag)
        
        lessonCollection.collectionView.frame = CGRect(x: 0, y: 0, width: collectionViewLayout.itemSize.width * 2 + 12, height: collectionViewLayout.itemSize.height * 2 + 20)
        
        [lessonView].forEach { label in
            lessonStack.addArrangedSubview(label)}

        lessonStack.addArrangedSubview(lessonCollection, withMargin: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0))
        
        setupCardParts([lessonStack])
    }
}


class LessonCell: CardPartCollectionViewCardPartsCell {
    
    let bag = DisposeBag()

    let lessonStack = CardPartStackView()
    let lessonTitle = CardPartTextView(type: .normal)
    let lessonDes = CardPartTextView(type: .title)

    override init(frame: CGRect) {

        super.init(frame: frame)

        lessonStack.axis = .vertical
        lessonStack.alignment = .center
        lessonStack.spacing = 10
        lessonStack.isLayoutMarginsRelativeArrangement = true
        lessonStack.layoutMargins = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
        
        lessonDes.textColor = .white
        
        lessonStack.addArrangedSubview(lessonTitle)
        lessonStack.addArrangedSubview(lessonDes)

        setupCardParts([lessonStack])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(_ data: LessonStruct) {

        lessonTitle.text = data.title
        lessonDes.text = data.description
    }
}
