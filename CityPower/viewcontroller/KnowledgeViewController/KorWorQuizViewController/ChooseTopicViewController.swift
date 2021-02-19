//
//  chooseTopicViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import RxDataSources


class ChooseTopicViewController: UIViewController, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var selectedButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    
    private let disposeBag = DisposeBag()
    private let transition = CATransition()
    private let tranDown = CATransition()
    
    var lastIndex: IndexPath!
    var viewModel: ChooseTopicViewModel!
    var topicChosen: String?
    var exit: Bool!
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.layer.add(self.transition, forKey: "UICollectionReloadDataAnimationKey")
        tableView.layer.add(self.transition, forKey: "UITableViewReloadDataAnimationKey")
        backButton.layer.add(self.transition, forKey: "UIBackViewReloadDataAnimationKey")
        selectedButton.layer.add(self.transition, forKey: "UISelectViewReloadDataAnimationKey")
        subject.layer.add(self.transition, forKey: "UISubjectReloadDataAnimationKey")
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ChooseTopicCollectViewCell {
            let subjectChosen = cell.topicLabel.text
            self.topicChosen = subjectChosen
            self.viewModel.reloadData(topic: subjectChosen!)
            self.tableView.isHidden = false
            self.collectionView.isHidden = true
            self.subject.isHidden = true
            self.backButton.isHidden = false
            self.selectedButton.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let noOfCellsInRow = 2
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))

        return CGSize(width: size, height: size + 20)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "CustomHeaderView") as! CustomHeaderView
        guard let topic = topicChosen else { return headerCell }
        headerCell.setData(topic)

        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 120
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let currentCell = tableView.cellForRow(at: indexPath) as? CustomTableViewCell else { return }
        let subjectChosen = currentCell.subjectView.text!
        currentCell.select = !currentCell.select
        
        if currentCell.select == true {
            viewModel.title.accept(subjectChosen)
        } else {
            viewModel.title.accept("เลือกวิชา")
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            currentCell.cellView.alpha = currentCell.select ? 1.0 : 0.5
        },  completion: { (finish) in
                self.backButton.isHidden = false
        })
        
        if (lastIndex != indexPath && lastIndex != nil) {
            
            let lastCell = tableView.cellForRow(at: lastIndex) as? CustomTableViewCell
            
            if lastCell?.select == true {
            
                lastCell?.select = !lastCell!.select

                UIView.animate(withDuration: 0.2, animations: {
                    lastCell?.cellView.alpha = lastCell!.select ? 1.0 : 0.5
                }, completion: nil)
            }
        }
        lastIndex = indexPath
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func setUpTable() {
    
        let dataSource = RxTableViewSectionedReloadDataSource<MySection>(
        configureCell: { dataSource, tableView, indexPath, item in
         
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as? CustomTableViewCell else { return UITableViewCell() }
        
        switch item {
        case .subject(let info):
             cell.setData(info)
        }
         
        return cell
        
        })
        
        //dataSource.titleForHeaderInSection = { dataSource, index in
          //  switch dataSource.sectionModels[index].model {
            //case .main (let info):
              //  return info.header
            //}
        //}
        
        viewModel.sections
        .bind(to: tableView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
    }
    
    func setUpCollect() {
    
        let dataSource = RxCollectionViewSectionedReloadDataSource<MySection>(configureCell: { (datasource, collectionView, indexPath, item) -> UICollectionViewCell in
            
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChooseTopicCollectViewCell", for: indexPath) as? ChooseTopicCollectViewCell else { return UICollectionViewCell() }
            
        switch item {
        case .subject(let info):
            cell.setData(info)
        }
            
        return cell
        })

        viewModel.sections.asObservable().bind(to: collectionView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        exit = false
        tableView.dataSource = nil
        tableView.allowsMultipleSelection = false
        tableView.separatorStyle = .none
        setUpTable()
       
        if let topic = topicChosen {
        viewModel.reloadData(topic: topic) }
        
        backButton.rx.tap.bind(onNext: { [weak self] in
            
            self?.subject.isHidden = false
            self?.topicChosen = nil
            self?.backButton.isHidden = true
            self?.selectedButton.isHidden = true
            self?.tableView.isHidden = true
            self?.collectionView.isHidden = false
            
            self?.subject.layer.add(self!.tranDown, forKey: "UISubjectReloadDataAnimationKey")
            self?.tableView.layer.add(self!.tranDown, forKey: "UITableViewReloadDataAnimationKey")
            self?.collectionView.layer.add(self!.tranDown, forKey: "UICollectionViewReloadDataAnimationKey")
            self?.selectedButton.layer.add(self!.tranDown, forKey: "UISelectViewReloadDataAnimationKey")
            self?.viewModel.setTopic()
            
            guard let lastIndex = self?.lastIndex else { return }
            
            let lastCell = self?.tableView.cellForRow(at: lastIndex) as! CustomTableViewCell
            
            if lastCell.select == true {
            
                lastCell.select = !lastCell.select

            UIView.animate(withDuration: 0.2, animations: {
                lastCell.cellView.alpha = lastCell.select ? 1.0 : 0.5
            }, completion: nil)}
            
        }).disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedButton.backgroundColor = .blueCity
        selectedButton.layer.cornerRadius = 25
        selectedButton.layer.shadowColor = UIColor.black.cgColor
        selectedButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        selectedButton.layer.shadowOpacity = 0.5
        selectedButton.layer.shadowRadius = 4.0
        selectedButton.isHidden = true
        selectedButton.setImage(UIImage(named: "icon60"), for: .normal)
        selectedButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        selectedButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        selectedButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        selectedButton.imageView?.contentMode = .scaleAspectFit
        selectedButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        transition.type = CATransitionType.push
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.fillMode = CAMediaTimingFillMode.forwards
        transition.duration = 0.5
        transition.subtype = CATransitionSubtype.fromTop
        
        tranDown.type = CATransitionType.push
        tranDown.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        tranDown.fillMode = CAMediaTimingFillMode.forwards
        tranDown.duration = 0.5
        tranDown.subtype = CATransitionSubtype.fromBottom
        
        collectionView.dataSource = nil
        
        selectedButton.rx.tap.bind(onNext: { [weak self] in
            if !self!.viewModel.title.value.contains("เลือกวิชา") {
                self?.viewModel.selectTopic()
                self?.viewModel.topic.accept(self?.topicChosen ?? "No topic") }
        }).disposed(by: disposeBag)
        
        exitButton.rx.tap.bind(onNext: { [weak self] in
            self?.viewModel.exitTopic()
            self?.exit = true
        }).disposed(by: disposeBag)

        backButton.isHidden = true
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        collectionView.delegate = self
        
        setUpCollect()
        viewModel.setTopic()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !exit && !viewModel.title.value.contains("เลือกวิชา") {
            viewModel.topic.accept(self.topicChosen ?? "No topic") }
    }
}


class ChooseTopicCollectViewCell: UICollectionViewCell {
    
    @IBOutlet weak var topicImage: UIImageView!
    @IBOutlet weak var topicView: UIView!
    @IBOutlet weak var topicLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        topicLabel.font = UIFont(name: "Baskerville-Bold", size: CGFloat(20))
        topicLabel.textColor = .white
    }
    
    func setData(_ data: MyStruct) {
        
        topicLabel.text = data.title
        setGradient(data.title)
    }
    
    func setGradient(_ title : String) {
        
        switch title {
        case "General":
            topicImage.image = UIImage(named: "catA-General0")
        case "Sanitary":
            topicImage.image = UIImage(named: "CatA-Sanitary0")
        case "Mechanic":
            topicImage.image = UIImage(named: "catA-Mechanical0")
        case "Electrical":
            topicImage.image = UIImage(named: "catA-Electrical0")
        default:
            topicImage.image = UIImage(named: "catA-General0")
        }
    }
}


class CustomHeaderView: UITableViewCell {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var imageCategory: UIImageView!
    @IBOutlet weak var categorySelected: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        categorySelected.font = UIFont(name: "Baskerville-Bold", size: CGFloat(24))
        categorySelected.textColor = .white
       }
    
    func setData(_ data: String) {
        
        categorySelected.text = data
        setGradient(data)
    }
    
    func setGradient(_ title : String) {
        
        switch title {
        case "General":
            imageCategory.image = UIImage(named: "catB-General0")
        case "Sanitary":
            imageCategory.image = UIImage(named: "catB-Sanitary0")
        case "Mechanic":
            imageCategory.image = UIImage(named: "catA-Mechanical_10")
        case "Electrical":
            imageCategory.image = UIImage(named: "catB-Electrical0")
        default:
            imageCategory.image = UIImage(named: "catB-General0")
        }

    }
}
