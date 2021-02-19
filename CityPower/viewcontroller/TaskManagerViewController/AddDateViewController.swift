//
//  AddDateViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 3/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift

class AddDateViewController: CardsViewController {
    
    var viewModel: AddDateViewModel!
    var addDateController: AddDateController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let cards: [CardController] = [addDateController]
 
        loadCards(cards: cards)
    }
    
}

class AddDateController: CardPartsViewController, UITextFieldDelegate {
    
    var viewModel: AddDateViewModel!
        
    let taskDateView = CardPartTextView(type: .normal)
    let taskDate = CardPartTextView(type: .normal)
    let taskTaskView = CardPartTextView(type: .normal)
    let taskManView = CardPartTextView(type: .normal)
    let taskTaskButton = CardPartButtonView()
    let taskManField = CardPartTextField(format: .none)
    let taskStack = CardPartStackView()
    let saveButton = CardPartButtonView()
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 2
    }
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()

        taskDateView.text = "Date"
        taskTaskView.text = "Task"
        taskManView.text = "ManPower"
        taskDateView.textColor = .blueCity
        taskTaskView.textColor =  .blueCity
        taskManView.textColor =  .blueCity
        taskDate.textColor =  .general2
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.blueCity, for: .normal)
        saveButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        saveButton.contentHorizontalAlignment = .center
        
        taskTaskButton.setTitleColor(.blueCity, for: .normal)
        
        taskManField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        taskManField.keyboardType = .numberPad
        taskManField.placeholder = "กรอกจำนวนแรงงาน"
        taskManField.textColor = .blueCity
        taskManField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        taskStack.axis = .vertical
        taskStack.spacing = 20
        taskStack.distribution = .equalSpacing
        taskStack.isLayoutMarginsRelativeArrangement = true
        taskStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        taskStack.pinBackground(taskStack.backgroundView, to: taskStack)
        
        [taskDateView, taskDate, taskTaskView, taskTaskButton, taskManView, taskManField, saveButton].forEach { label in
            taskStack.addArrangedSubview(label)}
        
        taskManField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let manPower = self.taskManField.text {
                self.viewModel.manPower.accept(manPower)}
            }).disposed(by: bag)
        
        saveButton.rx.tap.bind(onNext: viewModel.saveDate).disposed(by: bag)
        taskTaskButton.rx.tap.bind(onNext: viewModel.addTask).disposed(by: bag)
        viewModel.taskDate.asObservable().bind(to: taskDate.rx.text).disposed(by: bag)
        viewModel.taskSelected.asObservable().bind(to: taskTaskButton.rx.buttonTitle).disposed(by: bag)
      
        let desValidation = taskManField
            .rx.text.orEmpty
            .map({ $0.count > 0 && isStringContainsOnlyNumbers(string: $0)})
            .share(replay: 1)

        desValidation
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: bag)
        
        setupCardParts([taskStack])
    }

}
