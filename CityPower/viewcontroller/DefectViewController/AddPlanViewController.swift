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
import Firebase

class AddPlanViewController: CardsViewController {
    
    var viewModel: AddPlanViewModel!
    var addPlanController: AddPlanController!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        let cards: [CardController] = [addPlanController]
        
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
         
        loadCards(cards: cards)
    }
}


class AddPlanController: CardPartsViewController {
    
    var viewModel: AddPlanViewModel!
        
    let planTitle = CardPartTextView(type: .normal)
    let planArea = CardPartTextView(type: .normal)
    let planFloor = CardPartTextView(type: .normal)
    let planTitleField = CardPartTextField(format: .none)
    let planAreaField = CardPartTextField(format: .none)
    let planFloorField = CardPartTextField(format: .none)
    let currentDate = CardPartTextView(type: .normal)
    let dateView = CardPartTextView(type: .normal)
    let planImage = CardPartImageView()
    
    let titleStack = CardPartStackView()
    let areaStack = CardPartStackView()
    let floorStack = CardPartStackView()
    let planStack = CardPartStackView()
    let imageStack = CardPartStackView()
    let dateStack = CardPartStackView()
    
    let selectPlan = CardPartButtonView()
    let saveButton = CardPartButtonView()
    
    var completionHandler: (() -> Void)?
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()

        planTitle.text = "Plan Title"
        planArea.text = "Plan Area"
        planFloor.text = "Plan Floor"
        currentDate.text = "Date"

        planTitle.textColor = .blueCity
        planArea.textColor = .blueCity
        planFloor.textColor = .blueCity
        currentDate.textColor = .blueCity
        dateView.textColor = .general2
        
        planImage.contentMode = .scaleAspectFit
        planImage.addConstraint(NSLayoutConstraint(item: planImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50))
        
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
        
        planAreaField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        planAreaField.keyboardType = .default
        planAreaField.placeholder = "กรอกพื้นที่"
        planAreaField.textColor = .black
        planAreaField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        planFloorField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        planFloorField.keyboardType = .default
        planFloorField.placeholder = "กรอกชั้น"
        planFloorField.textColor = .black
        planFloorField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        selectPlan.setTitle("Select Plan 🔘", for: .normal)
        selectPlan.setTitleColor(.blueCity, for: .normal)
        selectPlan.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        [dateStack, titleStack, imageStack, floorStack, areaStack].forEach { stack in
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
        
        [planFloor, planFloorField].forEach { view in
            floorStack.addArrangedSubview(view)}
        
        [planArea, planAreaField].forEach { view in
            areaStack.addArrangedSubview(view)}
        
        [planTitle, planTitleField].forEach { view in
            titleStack.addArrangedSubview(view)}
        
        [selectPlan, planImage].forEach { view in
            imageStack.addArrangedSubview(view)}
        
        [dateStack, CardPartSeparatorView(), titleStack, areaStack, floorStack, CardPartSeparatorView(),
         imageStack, CardPartSeparatorView(), saveButton].forEach { view in
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
        
        planAreaField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let title = self.planAreaField.text {
                self.viewModel.planArea.accept(title)
            }
        }).disposed(by: bag)
        
        planFloorField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let title = self.planFloorField.text {
                self.viewModel.planFloor.accept(title)
            }
        }).disposed(by: bag)

        saveButton.rx.tap.bind(onNext: { [weak self] in

            let alert = UIAlertController(title: "Are you Sure ?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                
                self?.completionHandler = {
                    self?.viewModel.savePlan()
                }
                if let image = self?.planImage.image {
                    self?.uploadFile(image)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            self?.present(alert, animated: true, completion: nil)

        }).disposed(by: bag)
      
        let desValidation = planTitleField
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)
        
        desValidation
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: bag)
        
        setupCardParts([planStack])
    }
    
    private func uploadFile(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.3) else { return }
        let fileName = Int(Date.timeIntervalSinceReferenceDate * 1000)
        let imagePath = "DefectPicture" + "/\(fileName).jpg"
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let storageChild = storageRef.child(imagePath)
        
        storageChild.putData(imageData, metadata: nil) { [weak self] (metadata, error) in
                            
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Complete")
            }
                
            storageChild.downloadURL { (url, error) in
                guard let downloadURL = url, let completionHandler = self?.completionHandler else { return }
                    
                if let error = error {
                    print(error)
                } else {
                    self?.viewModel.imageLink.accept(downloadURL.absoluteString)
                    completionHandler()
                }
            }
        }
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

        self.dismiss(animated: true) { [weak self] in

            guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
            self?.planImage.image = image

        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
