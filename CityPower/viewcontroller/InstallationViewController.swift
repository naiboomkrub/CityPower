//
//  InstallationViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import UIKit


class InstallationViewController: CardsViewController {
    
    @IBOutlet weak var navBar: UINavigationItem!
    
    var viewModel: InstallationViewModel!
    var installationText: InstallationText!
    var installTable: InstallTable!
    
    private let disposeBag = DisposeBag()
    
    let logo = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logo.setTitle("History", for: .normal)
        logo.setTitleColor(.blueCity, for: .normal)
        logo.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
        logo.rx.tap.bind(onNext: viewModel.selectHistory).disposed(by: disposeBag)
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(logo)
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -8),
            logo.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -10),
            logo.heightAnchor.constraint(equalToConstant: 32),
            logo.widthAnchor.constraint(equalToConstant: 100) ])
        
        let cards: [CardController] = [installationText, installTable]
        loadCards(cards: cards)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logo.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logo.isHidden = false
    }
}

class InstallationText: CardPartsViewController, TransparentCardTrait {
    
    var viewModel: InstallationViewModel!
    
    let topicStack = CardPartStackView()
    let topic1 = CardPartPillLabel()
    let topic2 = CardPartPillLabel()
    let topic3 = CardPartPillLabel()
    let installTable = CardPartTableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        topic1.text = "Electrical"
        topic1.verticalPadding = 10
        topic1.horizontalPadding = 10
        topic1.backgroundColor = UIColor.lightGray
        topic1.textColor = UIColor.blueCity
        
        topic2.text = "Mechanical"
        topic2.verticalPadding = 10
        topic2.horizontalPadding = 10
        topic2.backgroundColor = UIColor.lightGray
        topic2.textColor = UIColor.blueCity
        
        topic3.text = "Sanitary"
        topic3.verticalPadding = 10
        topic3.horizontalPadding = 10
        topic3.backgroundColor = UIColor.lightGray
        topic3.textColor = UIColor.blueCity
        
        topicStack.axis = .horizontal
        topicStack.spacing = 5
        topicStack.distribution = .fillEqually
        topicStack.isLayoutMarginsRelativeArrangement = true
        topicStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 20, right: 60)
        
        [topic1, topic2, topic3].forEach { label in
            topicStack.addArrangedSubview(label)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(reloadTable))
        topic1.addGestureRecognizer(tap)
        topic1.isUserInteractionEnabled = true
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(reloadTable2))
        topic2.addGestureRecognizer(tap2)
        topic2.isUserInteractionEnabled = true
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(reloadTable3))
        topic3.addGestureRecognizer(tap3)
        topic3.isUserInteractionEnabled = true
        
        setupCardParts([topicStack])
        
    }
    
    @objc func reloadTable(_ sender: UITapGestureRecognizer) {
        
        viewModel.selectPill()
    }
    
    @objc func reloadTable2(_ sender: UITapGestureRecognizer) {
        
        viewModel.selectPill2()
    }
    
    @objc func reloadTable3(_ sender: UITapGestureRecognizer) {
        
        viewModel.selectPill3()
    }
    
}

class InstallTable: CardPartsViewController, CardPartTableViewDelegate, CustomMarginCardTrait {
    
    func customMargin() -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let currentCell = tableView.cellForRow(at: indexPath) as? CardPartTableViewCell else { return }
        viewModel.selectContent()
        viewModel.selectContentTitle.accept(currentCell.leftTitleLabel.text!)
    }
    
    var viewModel: InstallationViewModel!
    
    let installTable = CardPartTableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        installTable.tableView.allowsMultipleSelection = false
        installTable.tableView.dataSource = nil
        installTable.delegate = self
        installTable.margins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        viewModel.listData.asObservable().bind(to: installTable.tableView.rx.items) { tableView, index, data in
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: IndexPath(item: index, section: 0)) as? CardPartTableViewCell else { return UITableViewCell() }
            
            cell.leftTitleLabel.text = data
            cell.selectedBackgroundView = UIView(frame: CGRect.zero)
            cell.selectedBackgroundView?.backgroundColor = UIColor.blueCity
            cell.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    
            return cell
        }.disposed(by: bag)
        
        setupCardParts([installTable])
    }
}

