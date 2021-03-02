//
//  AddDefectViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 10/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift

class AddDefectViewController: CardsViewController {
    
    var viewModel: AddDefectViewModel!
    var addDefectController: AddDefectController!
        
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let cards: [CardController] = [addDefectController]
        
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        
        loadCards(cards: cards)
    }
    
}

class AddDefectController: CardPartsViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var viewModel: AddDefectViewModel!
    
    var selectedSection: String?
    var sectionList = ["Electrical", "Mechanical", "Sanitary", "General"]
        
    let defectDateView = CardPartTextView(type: .normal)
    let defectDate = CardPartTextView(type: .normal)
    let defectTitle = CardPartTextView(type: .normal)
    
    let infoStackHori = CardPartStackView()
    let dateStack = CardPartStackView()
    let dueStack = CardPartStackView()
    let posStack = CardPartStackView()
    
    let defectTitleField = CardPartTextField(format: .none)
    let sectionField = CardPartTextField(format: .none)
    let dueDate = CardPartTextView(type: .normal)
    let positionTag = CardPartTextView(type: .normal)
    let defectStack = CardPartStackView()
    let pickerView = UIPickerView()
    
    let selectPos = CardPartButtonView()
    let saveButton = CardPartButtonView()
    let datePicker = UIDatePicker()
    
    let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sectionList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sectionList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sectionField.text = sectionList[row]
        viewModel.systemChose.accept(sectionList[row])
    }
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()

        defectDateView.text = "Creation Date"
        defectTitle.text = "Defect Title"
        dueDate.text = "Due Date"
        positionTag.text = "Position"
        defectDateView.textColor = .blueCity
        defectTitle.textColor = .blueCity
        dueDate.textColor = .blueCity
        defectDate.textColor = .general2
        positionTag.textColor = .general2
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.blueCity, for: .normal)
        saveButton.setTitleColor(.general, for: .disabled)
        saveButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        saveButton.contentHorizontalAlignment = .center
        
        selectPos.setTitle("Select Location 🔘", for: .normal)
        selectPos.setTitleColor(.blueCity, for: .normal)
        selectPos.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        datePicker.date = Date()
        datePicker.locale = .current
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        sectionField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        sectionField.placeholder = "เลือกระบบ"
        sectionField.textColor = .black
        sectionField.delegate = self
        
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = .flexibleWidth
        pickerView.contentMode = .center
        pickerView(pickerView, didSelectRow: 0, inComponent: 0)
        
        let toolBar =  UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35))
        toolBar.barStyle = UIBarStyle.default
        toolBar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(action))
        
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        
        sectionField.inputView = pickerView
        sectionField.inputAccessoryView = toolBar
        
        defectTitleField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        defectTitleField.keyboardType = .default
        defectTitleField.placeholder = "กรอกข้อมูล Defect"
        defectTitleField.textColor = .black
        defectTitleField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        [dateStack, dueStack, posStack, infoStackHori].forEach { stack in
            stack.axis = .horizontal
            stack.spacing = 50
            stack.distribution = .equalSpacing
            stack.isLayoutMarginsRelativeArrangement = true
            stack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            stack.pinBackground(stack.backgroundView, to: stack)
        }

        [defectDateView, defectDate].forEach { view in
            dateStack.addArrangedSubview(view)}
        [dueDate, datePicker].forEach { view in
            dueStack.addArrangedSubview(view)}
        [selectPos, positionTag].forEach { view in
            posStack.addArrangedSubview(view)}
        [defectTitle, sectionField].forEach { view in
            infoStackHori.addArrangedSubview(view)}
        
        defectStack.axis = .vertical
        defectStack.spacing = 20
        defectStack.distribution = .equalSpacing
        defectStack.isLayoutMarginsRelativeArrangement = true
        defectStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        defectStack.pinBackground(defectStack.backgroundView, to: defectStack)
        
        [dateStack, CardPartSeparatorView(), infoStackHori, defectTitleField, CardPartSeparatorView(), dueStack, CardPartSeparatorView(), posStack, CardPartSeparatorView(), saveButton].forEach { view in
            defectStack.addArrangedSubview(view)}
        
        defectTitleField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let title = self.defectTitleField.text {
                self.viewModel.defectTitle.accept(title)
            }
        }).disposed(by: bag)
        
        viewModel.defectDate.asObservable().bind(to: defectDate.rx.text).disposed(by: bag)
        viewModel.resultPosition.map { "\($0.first?.pointNum ?? "")" }
            .asObservable().bind(to: positionTag.rx.text).disposed(by: bag)
        selectPos.rx.tap.bind(onNext: viewModel.addLocation).disposed(by: bag)
        
        saveButton.rx.tap.bind(onNext: { [weak self] in
            
            let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                self?.viewModel.saveDefect()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            self?.present(alert, animated: true, completion: nil)
            
        }).disposed(by: bag)
      
        let desValidation = defectTitleField
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)
        
        let sectionValidation = sectionField
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)

        let saveEnabled = Observable.combineLatest(desValidation, sectionValidation) {
            $0 && $1 }.share(replay: 1)

        saveEnabled
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: bag)
        
        setupCardParts([defectStack])
    }
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        viewModel.dueDate.accept(formatterDay.string(from: sender.date))
    }

    @objc func action() {
        sectionField.resignFirstResponder()
    }
}

