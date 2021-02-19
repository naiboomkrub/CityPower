//
//  ChooseLessonViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 9/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import RxDataSources


class ChooseLessonViewController: CardsViewController {
    
    var viewModel: ChooseLessonViewModel!
    var chooseLessonController: ChooseLessonController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.setTopic()
        let cards: [CardController] = [chooseLessonController]
        loadCards(cards: cards)
    }
}

class ChooseLessonController: CardPartsViewController , CardPartCollectionViewDelegte{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.startLesson()
    }
    
    var viewModel: ChooseLessonViewModel!
    
    let topicHead = CardPartTextView(type: .normal)
    
    lazy var subTopicCollection = CardPartCollectionView(collectionViewLayout: collectionViewLayout)
    var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 25
        layout.minimumLineSpacing = 25
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        return layout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topicHead.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
        topicHead.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        viewModel.topicHeader.asObservable().bind(to: topicHead.rx.text).disposed(by: bag)
        subTopicCollection.margins = UIEdgeInsets(top: 0, left: 10, bottom: 20, right: 10)
        subTopicCollection.collectionView.backgroundColor = .clear
        subTopicCollection.delegate = self
        subTopicCollection.collectionView.register(SubTopicCell.self, forCellWithReuseIdentifier: "SubTopicCell")
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionOfSubTopicStruct>(configureCell: { (_, collectionView, indexPath, data) -> UICollectionViewCell in

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubTopicCell", for: indexPath) as? SubTopicCell else { return UICollectionViewCell() }

            cell.setData(data)
            cell.layer.cornerRadius = 20
            cell.backgroundColor = .blueCity
            
            return cell
        })
        
        viewModel.data.asObservable().bind(to: subTopicCollection.collectionView.rx.items(dataSource: dataSource)).disposed(by: bag)
        
        subTopicCollection.collectionView.frame = CGRect(x: 0, y: 0, width: view.safeAreaLayoutGuide.layoutFrame.width, height: 180)
        
        setupCardParts([topicHead, subTopicCollection])
    }

}


class SubTopicCell: CardPartCollectionViewCardPartsCell {
    
    let bag = DisposeBag()

    let lessonStack = CardPartStackView()
    let lessonTitle = CardPartTextView(type: .normal)
    let lessonDes = CardPartTextView(type: .title)
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                self.transform = self.isSelected ? CGAffineTransform(scaleX: 1.1, y: 1.1) : CGAffineTransform.identity
                self.layer.cornerRadius = 20
                }, completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.transform = CGAffineTransform(scaleX: 1, y: 1) }
                })
            }
    }

    override init(frame: CGRect) {

        super.init(frame: frame)

        lessonStack.axis = .vertical
        lessonStack.alignment = .center
        lessonStack.spacing = 10
        lessonStack.isLayoutMarginsRelativeArrangement = true
        lessonStack.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
        lessonDes.textColor = .white
        
        lessonStack.addArrangedSubview(lessonTitle)
        lessonStack.addArrangedSubview(lessonDes)

        setupCardParts([lessonStack])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(_ data: SubTopicStruct) {

        lessonTitle.text = data.title
        lessonDes.text = data.description
    }
}
