//
//  SelectTaskViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 4/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import RxDataSources

class SelectTaskViewController: CardsViewController {
    
    var viewModel: SelectTaskViewModel!
    var selectTaskController: SelectTaskController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let cards: [CardController] = [selectTaskController]
 
        loadCards(cards: cards)
    }
    
}

class SelectTaskController: CardPartsViewController, CardPartTableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let currentCell = tableView.cellForRow(at: indexPath) as? CardPartTableViewCell else { return }
        viewModel.taskSelected.accept(currentCell.leftTitleLabel.text!)
        
        if lastCell == nil {
            currentCell.accessoryType = .checkmark
            lastCell = currentCell
        } else {
            currentCell.accessoryType = .checkmark
            lastCell.accessoryType = .none
            lastCell = currentCell
        }
    }
    
    var viewModel: SelectTaskViewModel!
    var lastCell: CardPartTableViewCell!
    
    let taskTable = CardPartTableView()
    
    func setUptable() {
        
        let dataSource = RxTableViewSectionedReloadDataSource<TaskSection>(
        configureCell: { dataSource, tableView, indexPath, item in
         
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: indexPath) as? CardPartTableViewCell else { return UITableViewCell() }
        
        switch item {
        case .subject(let info):
            cell.leftTitleLabel.text = info.taskTitle
            cell.selectedBackgroundView = UIView(frame: CGRect.zero)
            cell.selectedBackgroundView?.backgroundColor = UIColor.blueCity
            cell.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
         
        return cell
        
        })
        
        dataSource.titleForHeaderInSection = { dataSource, index in
            switch dataSource.sectionModels[index].model {
            case .main (let info):
                return info.header
            }
        }
        
        viewModel.sections
            .bind(to: taskTable.tableView.rx.items(dataSource: dataSource))
        .disposed(by: bag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        taskTable.tableView.allowsMultipleSelection = false
        taskTable.tableView.dataSource = nil
        taskTable.delegate = self
        taskTable.margins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        setUptable()
        
        setupCardParts([taskTable])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadData()
    }

}
