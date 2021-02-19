//
//  InstallContentViewController.swift
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


class InstallContentViewController: UIViewController,  UITableViewDelegate, InstallHeaderViewHeaderDelegate, UITableViewDataSource, UITextFieldDelegate {
        
    @IBOutlet weak var contentTable: UITableView!
    @IBOutlet weak var contentView: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var machineLabel: UITextField!
    
    var viewModel: InstallContentViewModel!
    var sections: [ContentSect]!
    
    let formatterHour: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm:ss"
         return formatter
     }()
    
    private let disposeBag = DisposeBag()
        
    @objc func valueChanged(_ textField: UITextField) {
        sections[0].items[textField.tag].value = textField.text ?? ""
    }
    
    func toggleSection(_ header: InstallHeader, section: Int) {
        
        let collapsed = !sections[section].collapsed
        var indexPathMain = [IndexPath]()
        
        for row in sections[section].items.indices {
            let indexPath = IndexPath(row: row, section: section)
            indexPathMain.append(indexPath)
        }
        sections[section].collapsed = collapsed
        header.setCollapsed(collapsed)
        
        if collapsed {
            contentTable.deleteRows(at: indexPathMain, with: .fade) }
        else {
            contentTable.insertRows(at: indexPathMain, with: .fade) }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item: ContentStruct = sections[indexPath.section].items[indexPath.row]
        
        if indexPath.section == 0 {
        
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "InputValueCell", for: indexPath) as? InputValueCell else { return UITableViewCell() }

            cell.setData(item)
            cell.valueField.delegate = self
            cell.valueField.tag = indexPath.row
            cell.valueField.addTarget(self, action: #selector(valueChanged), for: .editingChanged)
            
            return cell
        } else {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContentViewCell", for: indexPath) as? ContentViewCell else { return UITableViewCell() }
                
            cell.setData(item)

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let currentCell = tableView.cellForRow(at: indexPath) as? ContentViewCell else { return }
        
        if currentCell.selectButton.isSelected == true {
            currentCell.selectButton.isSelected = false
            sections[indexPath.section].items[indexPath.row].select = false
        }
        else {
            currentCell.selectButton.isSelected = true
            sections[indexPath.section].items[indexPath.row].select = true
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
           return 1.0
       }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].collapsed ? 0 : sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "InstallHeader") as? InstallHeader ?? InstallHeader(reuseIdentifier: "InstallHeader")
        
        headerCell.delegate = self
        headerCell.section = section
        headerCell.titleLabel.text = sections[section].header
        headerCell.arrowLabel.text = ">"
        headerCell.setCollapsed(sections[section].collapsed)
        
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 80
    }
            
    let gradientLayer = CAGradientLayer()
    let borderLayer = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.reloadData()
        self.sections = viewModel.sections

        contentTable.separatorStyle = .none
        contentTable.delegate = self
        contentTable.dataSource = self
        
        saveButton.setTitle("Save Checklist", for: .normal)
        saveButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))
        saveButton.setTitleColor(.white, for: .normal)
        
        contentView.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))
        contentView.textColor = .blueCity
        
        viewModel.contentTitle.asObservable().bind(to: contentView.rx.text).disposed(by: disposeBag)
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.colors =  [UIColor.start1.cgColor, UIColor.start2.cgColor]
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        saveButton.layer.shadowOpacity = 0.3
        saveButton.layer.shadowRadius = 4.0
        
        borderLayer.layer.cornerRadius = 30.0
        borderLayer.layer.masksToBounds = true
        borderLayer.layer.insertSublayer(gradientLayer, at: 0)
        
        viewModel.machineLabel.asObservable().bind(to: machineLabel.rx.text).disposed(by: disposeBag)
        
        saveButton.addSubview(borderLayer)
        saveButton.sendSubviewToBack(borderLayer)
        borderLayer.isUserInteractionEnabled = false
        
        saveButton.rx.tap.bind(onNext: { [unowned self] in
            var values: [String] = []
            var valuesHead: [String] = []
            var selected: [Bool] = []
            var selectedHead: [String] = []
            
            for i in 0..<(self.sections[0].items.count) {
                values.append((self.sections[0].items[i].value))
                valuesHead.append((self.sections[0].items[i].title))
            }
            
            for i in 0..<(self.sections[1].items.count) {
                selected.append((self.sections[1].items[i].select))
                selectedHead.append((self.sections[1].items[i].title))
            }
            
            self.viewModel.saveTask(InstallHistory(machineLabel : self.machineLabel.text ?? "", data1: self.sections[0].items, data2: self.sections[1].items, timeStamp: (self.formatterHour.string(from: Date())), topic: self.viewModel.contentTitle.value))
            
        }).disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.gradientLayer.frame = self.saveButton.bounds
        self.borderLayer.frame = self.saveButton.bounds
    }
}


class ContentViewCell: UITableViewCell {
    
    @IBOutlet weak var contentTitle: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        contentTitle.font = UIFont(name: "SukhumvitSet-Medium", size: CGFloat(20))
    }
    
    func setData (_ data: ContentStruct) {
        contentTitle.text = data.title
        selectButton.isSelected = data.select
    }
}


class InputValueCell: UITableViewCell {

    @IBOutlet weak var valueName: UILabel!
    @IBOutlet weak var valueField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        valueName.font = UIFont(name: "SukhumvitSet-Medium", size: CGFloat(20))
    }
    func setData (_ data: ContentStruct) {
        valueName.text = data.title
        valueField.text = data.value
    }
}


protocol InstallHeaderViewHeaderDelegate {
    func toggleSection(_ header: InstallHeader, section: Int)
}


class InstallHeader: UITableViewHeaderFooterView {
    
    var delegate: InstallHeaderViewHeaderDelegate?
    var section: Int = 0
    
    let titleLabel = UILabel()
    let arrowLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(InstallHeader.tapHeader(_:))))
        
        let marginGuide = contentView.layoutMarginsGuide
        contentView.backgroundColor = .blueCity
        
        contentView.addSubview(arrowLabel)
        arrowLabel.textColor = UIColor.white
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowLabel.widthAnchor.constraint(equalToConstant: 12).isActive = true
        arrowLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        arrowLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
        arrowLabel.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor).isActive = true
        
        contentView.addSubview(titleLabel)
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor).isActive = true
    
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapHeader(_ gestureRecognizer: UITapGestureRecognizer) {
        
        guard let cell = gestureRecognizer.view as? InstallHeader else {
            return
        }
        
        delegate?.toggleSection(self, section: cell.section)
    
    }
    
    func setCollapsed(_ collapsed: Bool) {
        
        arrowLabel.rotate(collapsed ? 0.0 : .pi / 2)
    }
}


extension UIView {

    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(animation, forKey: nil)
    }
}
