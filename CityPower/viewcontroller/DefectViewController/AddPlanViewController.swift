//
//  AddPlanViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 19/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift

class AddPlanViewController: CardsViewController {
    
    var viewModel: AddPlanViewModel!
    var addPlanController: AddPlanController!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        let cards: [CardController] = [addPlanController]
         
        loadCards(cards: cards)
    }
}


class AddPlanController: CardPartsViewController {
    
    var viewModel: AddPlanViewModel!
        
    let planTitle = CardPartTextView(type: .normal)
    let planTitleField = CardPartTextField(format: .none)
    let currentDate = CardPartTextView(type: .normal)
    let dateView = CardPartTextView(type: .normal)
    
    let titleStack = CardPartStackView()
    let planStack = CardPartStackView()
    let dateStack = CardPartStackView()
    
    let selectPlan = CardPartButtonView()
    let saveButton = CardPartButtonView()
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()

        planTitle.text = "Plan Title"
        currentDate.text = "Date"

        planTitle.textColor = .blueCity
        currentDate.textColor = .blueCity
        dateView.textColor = .general2
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.blueCity, for: .normal)
        saveButton.setTitleColor(.general, for: .disabled)
        saveButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        saveButton.contentHorizontalAlignment = .center

        planTitleField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        planTitleField.keyboardType = .default
        planTitleField.placeholder = "กรอกชื่อแบบ"
        planTitleField.textColor = .black
        planTitleField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        selectPlan.setTitle("Select Plan 🔘", for: .normal)
        selectPlan.setTitleColor(.blueCity, for: .normal)
        selectPlan.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        [dateStack, titleStack].forEach { stack in
            stack.axis = .horizontal
            stack.spacing = 50
            stack.distribution = .equalSpacing
            stack.isLayoutMarginsRelativeArrangement = true
            stack.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            stack.pinBackground(stack.backgroundView, to: stack)
        }
        
        planStack.axis = .vertical
        planStack.spacing = 20
        planStack.distribution = .equalSpacing
        planStack.isLayoutMarginsRelativeArrangement = true
        planStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        planStack.pinBackground(planStack.backgroundView, to: planStack)
        
        [currentDate, dateView].forEach { view in
            dateStack.addArrangedSubview(view)}
        
        [planTitle, planTitleField].forEach { view in
            titleStack.addArrangedSubview(view)}
        
        [dateStack, CardPartSeparatorView(), titleStack, CardPartSeparatorView(),
         selectPlan, CardPartSeparatorView(), saveButton].forEach { view in
            planStack.addArrangedSubview(view)}
        
        viewModel.defectDate.asObservable().bind(to: dateView.rx.text).disposed(by: bag)
        selectPlan.rx.tap.bind(onNext: { [weak self] in
            self?.didTapOnImageView()
        }).disposed(by: bag)
        
        planTitleField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let title = self.planTitleField.text {
                self.viewModel.planName.accept(title)
            }
        }).disposed(by: bag)

        saveButton.rx.tap.bind(onNext: { [weak self] in

            let alert = UIAlertController(title: "Are you Sure ?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                //self?.viewModel.saveComment()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            self?.present(alert, animated: true, completion: nil)

        }).disposed(by: bag)
      
        let desValidation = planTitleField
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)
        
//        let topicValidation = commentTitleField
//            .rx.text.orEmpty
//            .map({ $0.count > 0 })
//            .share(replay: 1)
//
//        let saveEnabled = Observable.combineLatest(desValidation, topicValidation) { $0 && $1 }.share(replay: 1)
        
        desValidation
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: bag)
        
        setupCardParts([planStack])
    }
    
}


extension AddPlanController: UIImagePickerControllerDelegate & UINavigationControllerDelegate  {
    
    func didTapOnImageView() {
        showAlert()
    }
    
    func showAlert() {

        let alert = UIAlertController(title: "Image Selection", message: "Please Select Image", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Photo Album", style: .default, handler: {(action: UIAlertAction) in
            self.getImage(fromSourceType: .photoLibrary)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        alert.pruneNegativeWidthConstraints()
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
        
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            imagePickerController.allowsEditing = true

            self.present(imagePickerController, animated: true, completion: nil)
            
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        //self.dismiss(animated: true) { [weak self] in

           // guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }

      //  }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
