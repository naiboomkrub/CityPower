//
//  AddTaskViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 2/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift

class AddTaskViewController: CardsViewController {
    
    var viewModel: AddTaskViewModel!
    var addTaskController: AddTaskController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let cards: [CardController] = [addTaskController]
 
        loadCards(cards: cards)
    }
    
}

class AddTaskController: CardPartsViewController {
    
    var viewModel: AddTaskViewModel!
        
    let taskDesView = CardPartTextView(type: .normal)
    let taskMandayView = CardPartTextView(type: .normal)
    let taskDesField = CardPartTextField(format: .none)
    let taskMandayField = CardPartTextField(format: .none)
    let taskStack = CardPartStackView()
    let saveButton = CardPartButtonView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskDesView.text = "Task Description"
        taskMandayView.text = "Manday"
        taskDesView.textColor = .blueCity
        taskMandayView.textColor =  .blueCity
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.blueCity, for: .normal)
        saveButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        saveButton.contentHorizontalAlignment = .center
        
        taskDesField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        taskDesField.keyboardType = .numberPad
        taskDesField.placeholder = "กรอกชื่องาน"
        taskDesField.textColor = .blueCity
        taskDesField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        taskMandayField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        taskMandayField.keyboardType = .numberPad
        taskMandayField.placeholder = "กรอกจำนวนแรงงาน"
        taskMandayField.textColor = .blueCity
        taskMandayField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        taskStack.axis = .vertical
        taskStack.spacing = 20
        taskStack.distribution = .equalSpacing
        taskStack.isLayoutMarginsRelativeArrangement = true
        taskStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        taskStack.pinBackground(taskStack.backgroundView, to: taskStack)
        
        [taskDesView, taskDesField, taskMandayView, taskMandayField, saveButton].forEach { label in
            taskStack.addArrangedSubview(label)}
        
        saveButton.rx.tap.bind(onNext: viewModel.saveTask).disposed(by: bag)
        
        viewModel.taskDesc.asObservable().bind(to: taskDesField.rx.text).disposed(by: bag)
        viewModel.manDay.asObservable().bind(to: taskMandayField.rx.text).disposed(by: bag)
        
        taskDesField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let descrip = self.taskDesField.text {
                self.viewModel.changeTask(descrip)}
            }).disposed(by: bag)
        
        taskMandayField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let manday = self.taskMandayField.text {
                self.viewModel.changeManDay(manday)}
            }).disposed(by: bag)
        
        let desValidation = taskDesField
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)

        let manValidation = taskMandayField
            .rx.text.orEmpty
            .map({ $0.count > 0 && isStringContainsOnlyNumbers(string: $0)})
            .share(replay: 1)

        let saveEnabled = Observable.combineLatest(desValidation, manValidation) {
            $0 && $1 }.share(replay: 1)

        saveEnabled
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: bag)
        
        setupCardParts([taskStack])
    }

}
