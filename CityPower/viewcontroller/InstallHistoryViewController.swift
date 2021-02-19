//
//  InstallHistoryViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 12/1/2564 BE.
//  Copyright © 2564 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources


class InstallHistoryViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var historyLabel: UILabel!
    @IBOutlet weak var historyTab: UITableView!
    @IBOutlet weak var editButton: UIButton!
    
    var viewModel: InstallHistoryViewModel!
    
    private let disposeBag = DisposeBag()
    
    typealias HistoryAllSection = AnimatableSectionModel<String, InstallHistory>
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<HistoryAllSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
        viewModel.dataSource
            .map { [HistoryAllSection(model: "", items: $0)] }
            .bind(to: historyTab.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        historyTab.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            self.viewModel.removeData(index: indexPath)
            
            if InstallHistories.shared.savedTask.count == 0 {
                self.historyTab.setEmptyMessage("Please Insert Installation")
            }
            
        }).disposed(by: disposeBag)
        
        historyTab.rx.itemMoved
            .subscribe(onNext: { [unowned self] source, destination in
                guard source != destination else { return }
                let item = self.viewModel.dataSource.value[source.row]
                self.viewModel.swapData(index: source, insertIndex: destination, element: item)
            })
            .disposed(by: disposeBag)
        
        historyTab.rx.modelSelected(InstallHistory.self)
            .subscribe(onNext: { [unowned self] history in
                self.viewModel.selectData(history)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        historyLabel.textColor = .black
        historyLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(28))!
        historyLabel.text = "Installation History"

        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.blueCity, for: .normal)
        editButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        editButton.rx.tap
            .map { [unowned self] in self.historyTab.isEditing }
            .bind(onNext: { [unowned self] result in
                self.historyTab.setEditing(!result, animated: true)
                if !result { self.editButton.setTitle("Done", for: .normal) }
                else { self.editButton.setTitle("Edit", for: .normal) }
            })
            .disposed(by: disposeBag)
        
        historyTab.separatorStyle = .none
        historyTab.rx.setDelegate(self).disposed(by: disposeBag)
        historyTab.dataSource = nil
        setUpTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if InstallHistories.shared.savedTask.count == 0 {
            historyTab.setEmptyMessage("Please Insert Installation")
        } else {
            viewModel.loadHistory()
        }
    }
}


class HistoryTableCell: UITableViewCell {
    
    @IBOutlet weak var historyProgress: UILabel!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var historyView: UIView!
    
    var ratio: CGFloat = 0.0
    
    let bg = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.historyView.layer.cornerRadius = 10.0
        self.historyView.layer.borderWidth = 0.5
        self.historyView.clipsToBounds = true

        bg.backgroundColor = .lightBlueCity
        self.historyView.addSubview(bg)
        self.historyView.sendSubviewToBack(bg)
        
        self.cellLabel.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
        self.historyProgress.font = UIFont(name: "Baskerville-Bold", size: CGFloat(16))!
        
    }
    
    override func draw(_ rect: CGRect) {
        bg.frame = self.historyView.frame
        bg.frame.size.width = frame.size.width * ratio
        bg.frame.origin.y = 0
        bg.frame.origin.x = 0
    }
    
    func setData (_ data: InstallHistory) {
        self.cellLabel.text = data.machineLabel
                
        var countTrue = 0.0
        var countAll = 0.0
        for str in data.data2 {
            countAll += 1.0
            if str.select {
                countTrue += 1.0
            }
        }
        ratio = CGFloat(countTrue / countAll)
        self.historyProgress.text = "\(Int(countTrue)) / \(Int(countAll))"
    }
}


extension InstallHistoryViewController {
    
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<HistoryAllSection>.ConfigureCell {
        return {  _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableCell", for: indexPath) as? HistoryTableCell else { return UITableViewCell() }
            
            cell.setData(item)
            cell.setNeedsDisplay()
            
            return cell
        }
    }
        
    private var canEditRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<HistoryAllSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.historyTab.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    private var canMoveRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<HistoryAllSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return true
        }
    }
}
