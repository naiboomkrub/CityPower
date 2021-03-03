//
//  SiteDetailViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import UIKit


class SiteDetailViewController: CardsViewController {

    var viewModel: SiteDetailViewModel!
    var siteDetailController: SiteDetailController!
    var statusTable: StatusTable!
    var durationTable: DurationTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.reloadStatus()
        viewModel.reloadDuration()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        let statusHead = TableHeadController()
        statusHead.tableHead.text = "Defect Status"
        let durationHead = TableHeadController()
        durationHead.tableHead.text = "Defect Duration"
        
        let cards: [CardController] = [siteDetailController, statusHead, statusTable, durationHead, durationTable]
        loadCards(cards: cards)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navViews = navigationController?.navigationBar.subviews {
            for logo in navViews {
                if let logo = logo as? UIButton {
                    UIView.animate(withDuration: 0.2) {
                        logo.alpha = 0.0
                    }
                }
            }
        }
    }
}


class SiteDetailController: CardPartsViewController, CustomMarginCardTrait {
    
    func customMargin() -> CGFloat {
        return 20
    }
        
    var viewModel: SiteDetailViewModel!

    let numberOfDefect = CardPartTextView(type: .normal)
    let defectNumber = CardPartTextView(type: .normal)
    let defectButton = CardPartButtonView()
    let buttonStack = CardPartStackView()
    
    let defectLayer = CAGradientLayer()
    let defectBorder = UIView()
    let numberStack = CardPartStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        numberStack.axis = .horizontal
        numberStack.distribution = .equalSpacing
        numberStack.isLayoutMarginsRelativeArrangement = true
        numberStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        numberStack.pinBackground(numberStack.backgroundView, to: numberStack)
        
        numberOfDefect.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
        numberOfDefect.text = "Total Defects : "
        defectNumber.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(16))!

        viewModel.totalDefect.asObservable().bind(to: defectNumber.rx.text).disposed(by: bag)
        defectButton.rx.tap.bind(onNext: viewModel.selectDefect).disposed(by: bag)

        [numberOfDefect, defectNumber].forEach { label in
            numberStack.addArrangedSubview(label)
        }
        
        setUpButton(defectButton, "Start", UIColor.white, "icon020", buttonStack, [UIColor.start1, UIColor.start2], defectLayer, defectBorder)

        setupCardParts([numberStack, buttonStack])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
                                                     
        self.defectLayer.frame = self.buttonStack.bounds
        self.defectBorder.frame = self.buttonStack.bounds
    }
    
    private func setUpButton(_ buttonPart: CardPartButtonView, _ text: String, _ color: UIColor, _ icon: String, _ stackView: CardPartStackView, _ colours: [UIColor], _ gradient: CAGradientLayer, _ borderView: UIView) {
        
        buttonPart.setTitle(text, for: .normal)
        buttonPart.setTitleColor(color, for: .normal)
        buttonPart.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        buttonPart.contentHorizontalAlignment = .center
        buttonPart.contentEdgeInsets = UIEdgeInsets(top: 15, left: 40, bottom: 15, right: 40)
        
        setGradient(stack: stackView, colours: colours, gradient: gradient, borderView: borderView, radius: 10)
        stackView.pinBackground(stackView.backgroundView, to: stackView)
        stackView.addArrangedSubview(buttonPart)
        stackView.margins = UIEdgeInsets(top: 20, left: 60, bottom: 30, right: 60)
    }
}

class TableHeadController: CardPartsViewController, TransparentCardTrait {
    
    let tableHead = CardPartTextView(type: .header)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableHead.textColor = .blueCity
        tableHead.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(28))!
        tableHead.margins = UIEdgeInsets(top: 20, left: 30, bottom: 10, right: 20)
        setupCardParts([tableHead])
    }
}

class StatusTable: CardPartsViewController, CardPartTableViewDelegate, CustomMarginCardTrait {
    
    func customMargin() -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      //  guard let currentCell = tableView.cellForRow(at: indexPath) as? CardPartTableViewCell else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    var viewModel: SiteDetailViewModel!
    
    let statusTable = CardPartTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusTable.tableView.allowsMultipleSelection = false
        statusTable.tableView.dataSource = nil
        statusTable.delegate = self
        statusTable.margins = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        
//        statusTable.tableView.rx.modelSelected(Task.self)
//            .subscribe(onNext: { [unowned self] task in
//                //self.viewModel.taskDone(taskClick: task)
//            })
//            .disposed(by: bag)
        
        viewModel.statusData.asObservable().bind(to: statusTable.tableView.rx.items) { tableView, index, data in
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: IndexPath(item: index, section: 0)) as?  CardPartTableViewCell else { return UITableViewCell() }
            
            cell.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            cell.leftTitleLabel.text = data.label
            cell.rightTitleLabel.text = data.count
            
            return cell
        }.disposed(by: bag)
    
        setupCardParts([statusTable])
    }
}

class DurationTable: CardPartsViewController, CardPartTableViewDelegate, CustomMarginCardTrait {
    
    func customMargin() -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      //  guard let currentCell = tableView.cellForRow(at: indexPath) as? CardPartTableViewCell else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    var viewModel: SiteDetailViewModel!
    
    let durationTable = CardPartTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        durationTable.tableView.allowsMultipleSelection = false
        durationTable.tableView.dataSource = nil
        durationTable.delegate = self
        durationTable.margins = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        
//        durationTable.tableView.rx.modelSelected(Task.self)
//            .subscribe(onNext: { [unowned self] task in
//               // self.viewModel.taskDone(taskClick: task)
//            })
//            .disposed(by: bag)
        
        viewModel.durationData.asObservable().bind(to: durationTable.tableView.rx.items) { tableView, index, data in
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: IndexPath(item: index, section: 0)) as?  CardPartTableViewCell else { return UITableViewCell() }
            
            cell.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            cell.leftTitleLabel.text = data.label
            cell.rightTitleLabel.text = data.count
            
            return cell
        }.disposed(by: bag)

        setupCardParts([durationTable])
    }
}
