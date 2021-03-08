//
//  AddCommentViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 15/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift

class AddCommentViewController: CardsViewController {
    
    var viewModel: AddCommentViewModel!
    var addCommentController: AddCommentController!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        let cards: [CardController] = [addCommentController]
         
        loadCards(cards: cards)
    }
}


class AddCommentController: CardPartsViewController {
    
    var viewModel: AddCommentViewModel!
        
    let commentTitle = CardPartTextView(type: .normal)
    let commentTitleField = CardPartTextField(format: .none)
    let commentBody = CardPartTextView(type: .normal)
    let commentStack = CardPartStackView()
    let seperateView = CardPartSeparatorView()
    let spacerView = CardPartSpacerView(height: 30)
    let multiline = MultilineTextField(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
    let saveButton = CardPartButtonView()
                
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()

        commentTitle.text = "Comment Title"
        commentBody.text = "Comment Description"

        commentTitle.textColor = .blueCity
        commentBody.textColor = .blueCity
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.blueCity, for: .normal)
        saveButton.setTitleColor(.general, for: .disabled)
        saveButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        saveButton.contentHorizontalAlignment = .center

        commentTitleField.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        commentTitleField.keyboardType = .default
        commentTitleField.placeholder = "กรอกหัวข้อ Comment"
        commentTitleField.textColor = .black
        commentTitleField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        commentStack.axis = .vertical
        commentStack.spacing = 20
        commentStack.distribution = .equalSpacing
        commentStack.isLayoutMarginsRelativeArrangement = true
        commentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        commentStack.pinBackground(commentStack.backgroundView, to: commentStack)
        
        multiline.placeholder = "กรอกข้อมูล Comment"
        multiline.backgroundColor = .white
        multiline.textColor = .black
        multiline.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        multiline.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        multiline.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        
        [commentTitle, commentTitleField, commentBody, multiline, spacerView, seperateView, saveButton].forEach { view in
            commentStack.addArrangedSubview(view)}
        
        multiline.rx.text.subscribe(onNext: { [unowned self] title in
            if let title = title {
                self.viewModel.commentBody.accept(title)
            }
        }).disposed(by: bag)
        
        commentTitleField.rx.controlEvent(.editingChanged).subscribe(onNext: { [unowned self] in
            if let title = self.commentTitleField.text {
                self.viewModel.commentTopic.accept(title)
            }
        }).disposed(by: bag)
        
        viewModel.commentTopic.asObservable().bind(to: commentTitleField.rx.text).disposed(by: bag)
        viewModel.commentBody.asObservable().bind(to: multiline.rx.text).disposed(by: bag)
        
        viewModel.editComment.asObservable().subscribe(onNext: { [weak self] model in
            if !model.isEmpty {
                self?.viewModel.commentTopic.accept(model[0].title)
                self?.viewModel.commentBody.accept(model[0].value)
            } else {
                self?.viewModel.commentTopic.accept("")
                self?.viewModel.commentBody.accept("")
            }
        }).disposed(by: bag)

        saveButton.rx.tap.bind(onNext: { [weak self] in

            let alert = UIAlertController(title: "Are you Sure ?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                self?.viewModel.saveComment()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            self?.present(alert, animated: true, completion: nil)

        }).disposed(by: bag)
      
        let desValidation = multiline
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)
        
        let topicValidation = commentTitleField
            .rx.text.orEmpty
            .map({ $0.count > 0 })
            .share(replay: 1)

        let saveEnabled = Observable.combineLatest(desValidation, topicValidation) { $0 && $1 }.share(replay: 1)
        
        saveEnabled
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: bag)
        
        setupCardParts([commentStack])
    }
    
}
