//
//  DefectDetailViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import CardParts
import Firebase
import RxDataSources

class DefectDetailViewController: CardsViewController {
    
    var viewModel: DefectDetailViewModel!
    var commentTable: CommentTable!
    var photoTable: PhotoTable!
    var defectDetailController: DefectDetailController!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        if let navViews = navigationController?.navigationBar.subviews {
            for logo in navViews {
                if let logo = logo as? UIButton {
                    UIView.animate(withDuration: 0.2) {
                        logo.alpha = 0.0
                    }
                }
            }
        }

        navigationItem.largeTitleDisplayMode = .never
        view.subviews.first?.backgroundColor = .blueCity
        
        let photoController = HeadController()
        photoController.setText("Photo")
                
        viewModel.photoState.asObservable().bind(onNext: { [unowned self] state in
            if state == .empty {
                photoController.editButton.setTitle("Edit", for: .normal)
                self.photoTable.photoTable.tableView.setEditing(false, animated: true)
            }
        }).disposed(by: disposeBag)
        
        photoController.editButton.rx.tap
            .map { [unowned self] in self.photoTable.photoTable.tableView.isEditing }
            .bind(onNext: { [unowned self] result in
                self.photoTable.photoTable.tableView.setEditing(!result, animated: true)
                if !result {  photoController.editButton.setTitle("Done", for: .normal) }
                else {  photoController.editButton.setTitle("Edit", for: .normal) }
            }).disposed(by: disposeBag)
        
        let commentController = HeadController()
        commentController.setText("Comment")
        
        viewModel.state.asObservable().bind(onNext: { [unowned self] state in
            if state == .empty {
                commentController.editButton.setTitle("Edit", for: .normal)
                self.commentTable.commentTable.tableView.setEditing(false, animated: true)
            }
        }).disposed(by: disposeBag)
        
        commentController.editButton.rx.tap
            .map { [unowned self] in self.commentTable.commentTable.tableView.isEditing }
            .bind(onNext: { [unowned self] result in
                self.commentTable.commentTable.tableView.setEditing(!result, animated: true)
                if !result {  commentController.editButton.setTitle("Done", for: .normal) }
                else {  commentController.editButton.setTitle("Edit", for: .normal) }
            }).disposed(by: disposeBag)
        
        let cards: [CardController] = [defectDetailController, commentController, commentTable, photoController, photoTable]
        loadCards(cards: cards)
    }
}


class DefectDetailController: CardPartsViewController, CustomMarginCardTrait {
    
    func customMargin() -> CGFloat {
        return 20
    }
        
    var viewModel: DefectDetailViewModel!

    let defectView = CardPartImageView()
    let defectTitle = CardPartTextView(type: .normal)
    let defectCreate = CardPartTextView(type: .normal)
    let defectDue = CardPartTextView(type: .normal)
    let defectImage = CardPartImageView()
    
    let addImage = CardPartButtonView()
    let addComment = CardPartButtonView()
    let done = CardPartButtonView()
    let doneStack = CardPartStackView()
    
    let dateStack = CardPartStackView()
    let defectStack = CardPartStackView()
    let buttonStack = CardPartStackView()
    let imageStack = CardPartStackView()
    
    let addImageDes = CardPartTextView(type: .normal)
    let addCommentDes = CardPartTextView(type: .normal)
    
    let doneLayer = CAGradientLayer()
    let doneBorder = UIView()
        
    private var completion = { }
    private var imageRequest: [ImageRequestId: UIImageView] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defectStack.axis = .vertical
        defectStack.alignment = .center
        defectStack.spacing = 10
        defectStack.isLayoutMarginsRelativeArrangement = true
        defectStack.layoutMargins = UIEdgeInsets.zero
        defectStack.margins = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        
        imageStack.axis = .vertical
        imageStack.alignment = .center
        imageStack.spacing = 0
        imageStack.isLayoutMarginsRelativeArrangement = true
        imageStack.layoutMargins = UIEdgeInsets.zero
        imageStack.margins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        imageStack.clipsToBounds = true
        
        dateStack.axis = .vertical
        dateStack.spacing = 10
        dateStack.isLayoutMarginsRelativeArrangement = true
        dateStack.layoutMargins = UIEdgeInsets(top: 5, left: 30, bottom: 5, right: 30)
        dateStack.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        dateStack.pinBackground(dateStack.backgroundView, to: dateStack)
                
        defectView.contentMode = .scaleAspectFit
        defectView.addConstraint(NSLayoutConstraint(item: defectView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 200))
        
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.spacing = 50
        buttonStack.isLayoutMarginsRelativeArrangement = true
        buttonStack.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)

        setUpButton(done, "Done", UIColor.white, "icon020", doneStack, [UIColor.start1, UIColor.start2], doneLayer, doneBorder)
        
        defectTitle.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(24))!
        defectCreate.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
        defectDue.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
        
        viewModel.title.asObservable().bind(to: defectTitle.rx.text).disposed(by: bag)
        viewModel.createDate.asObservable().bind(to: defectCreate.rx.text).disposed(by: bag)
        viewModel.dueDate.asObservable().bind(to: defectDue.rx.text).disposed(by: bag)
        
        viewModel.photos.asObservable().bind(onNext: { [weak self] photo in
                                       
            guard !photo.isEmpty else { return }
            
            for image in photo {
                
                let imageHolder = UIImageView()
                imageHolder.contentMode = .scaleAspectFit
                imageHolder.bounds.size = CGSize(width: 750, height: 1334)
                
                let id = imageHolder.setImage(fromSource: image,
                placeholderDeferred: true,
                adjustOptions: { option in
                        option.deliveryMode = .best
                }, resultHandler: { (result: ImageRequestResult<UIImage>) in
                
                    if let imageToUpload = result.image, let imageRequest = self?.imageRequest {
                        self?.imageRequest = imageRequest.filter { $0.key != result.requestId }
                        self?.uploadFile(imageToUpload)
                    }
                })
                if let id = id {
                    self?.imageRequest[id] = imageHolder
                }
            }
        }).disposed(by: bag)
        
        done.rx.tap.bind(onNext: { [weak self] in

            let alert = UIAlertController(title: "Defect Done", message: "Please Confirm", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertAction.Style.default, handler: { action in
                self?.viewModel.doneDefect()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            self?.present(alert, animated: true, completion: nil)
            
        }).disposed(by: bag)
        
        Observable.combineLatest(viewModel.imageName, viewModel.positionDefect)
            .subscribe(onNext: { [weak self] image, position in
            
            guard let url = URL(string: image), let index = DefectDetails.shared.currentIndex else { return }
            
            self?.completion = {
                DispatchQueue.main.async {
                    if !position.isEmpty,
                       let width = self?.defectView.frame.width,
                       let height = self?.defectView.frame.height,
                       let imgSize = self?.defectView.image?.size {
//                       let tr = self?.defectView.transform.scaledBy(x: 1.25, y: 1.25) {

                        let aspectWidth  = width / imgSize.width
                        let aspectHeight = height / imgSize.height
                        let f = min(aspectWidth, aspectHeight)
                        let pos = position[0]
        
                        var imagePoint = pos
                            
                        imagePoint.y *= f
                        imagePoint.x *= f
                        imagePoint.x += (width - imgSize.width * f) / 2.0
                        imagePoint.y += (height - imgSize.height * f) / 2.0

                        let tempView = TemView()
                        tempView.setText("\(index)")
                        tempView.bounds.size = CGSize(width: 50, height: 70)
                        tempView.frame.origin = imagePoint
                        tempView.layer.borderColor = UIColor.blueCity.cgColor
                        tempView.backgroundColor = .clear
                        
                        self?.defectView.addSubview(tempView)
                        
//                        self?.defectView.layer.anchorPoint = CGPoint(x: (imagePoint.x + 25) / width,
//                                                                     y: (imagePoint.y + 35) / height)
//                        self?.defectView.layer.transform = CATransform3DMakeAffineTransform(tr)
                        
                    }
                }
            }

            let pipeline = DataPipeLine.shared
            let request = DataRequest(url: url, processors: [])

            if let container = pipeline.cachedImage(for: request) {
                self?.defectView.image = container.image
                self?.completion()
                return
            }
            
            pipeline.loadImage(with: request) { [weak self] result in
                if case let .success(response) = result {
                    self?.defectView.image  = response.image
                    self?.completion()
                }
            }

        }).disposed(by: bag)
        
        [createStack(addImageDes, addImage), createStack(addCommentDes, addComment)].forEach { label in
            buttonStack.addArrangedSubview(label)
        }

        imageStack.addArrangedSubview(defectView)

        [defectCreate, defectDue].forEach { label in
            dateStack.addArrangedSubview(label)
        }
        
        [defectTitle, buttonStack].forEach { label in
            defectStack.addArrangedSubview(label)
        }
        
        setupCardParts([imageStack, defectStack, CardPartSeparatorView(), dateStack, CardPartSeparatorView(), doneStack])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
                                                     
        self.doneLayer.frame = self.doneStack.bounds
        self.doneBorder.frame = self.doneStack.bounds
        addImage.layer.cornerRadius = 0.5 * addImage.bounds.size.width
        addComment.layer.cornerRadius = 0.5 * addComment.bounds.size.width
    }
    
    private func uploadFile(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
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
                guard let downloadURL = url else { return }
                    
                if let error = error {
                    print(error)
                } else {
                    print(downloadURL)
                    self?.viewModel.addPhoto(downloadURL.absoluteString, "\(fileName)")
                }
            }
        }
    }
}


extension DefectDetailController {
    
    private func setUpButton(_ buttonPart: CardPartButtonView, _ text: String, _ color: UIColor, _ icon: String, _ stackView: CardPartStackView, _ colours: [UIColor], _ gradient: CAGradientLayer, _ borderView: UIView) {
        
        buttonPart.setTitle(text, for: .normal)
        buttonPart.setTitleColor(color, for: .normal)
        buttonPart.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        buttonPart.contentHorizontalAlignment = .center
        buttonPart.contentEdgeInsets = UIEdgeInsets(top: 15, left: 40, bottom: 15, right: 40)
        
        setGradient(stack: stackView, colours: colours, gradient: gradient, borderView: borderView, radius: 10)
        stackView.pinBackground(stackView.backgroundView, to: stackView)
        stackView.addArrangedSubview(buttonPart)
        stackView.margins = UIEdgeInsets(top: 20, left: 60, bottom: 30, right: 60)
    }
    
    private func createStack(_ labelPart: CardPartTextView, _ buttonImage: CardPartButtonView) -> CardPartStackView {
        
        let buttonWithDes = CardPartStackView()
        
        labelPart.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(12))!
        labelPart.textColor = .general
        labelPart.margins = UIEdgeInsets.zero
        
        buttonImage.margins = UIEdgeInsets.zero
        buttonImage.clipsToBounds = true
        buttonImage.layer.borderWidth = 1.0
        buttonImage.layer.borderColor = UIColor.general.cgColor
        buttonImage.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        buttonImage.contentMode = .scaleAspectFit
        
        switch labelPart {
        
            case addCommentDes:
                labelPart.text = "Comment"
                buttonImage.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .heavy)), for: .normal)
                buttonImage.rx.tap.bind(onNext: { [weak self] in
                    self?.viewModel.addComment()
                }).disposed(by: bag)
                
            case addImageDes:
                labelPart.text = "Image"
                buttonImage.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .heavy)), for: .normal)
                buttonImage.rx.tap.bind(onNext: { [weak self] in
                    self?.viewModel.photoEdit()
                }).disposed(by: bag)
            default:
                return CardPartStackView()
        }
        
        buttonWithDes.alignment = .center
        buttonWithDes.axis = .vertical
        buttonWithDes.spacing = 10
        buttonWithDes.isLayoutMarginsRelativeArrangement = true
        buttonWithDes.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
        [buttonImage, labelPart].forEach { label in
            buttonWithDes.addArrangedSubview(label)
        }
        return buttonWithDes
    }
}


class HeadController: CardPartsViewController, TransparentCardTrait {
    
    private let commentHead = CardPartTextView(type: .header)
    private let stackView = CardPartStackView()
    
    let editButton = CardPartButtonView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        stackView.margins = UIEdgeInsets(top: 10, left: 30, bottom: 0, right: 40)
        
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.white, for: .normal)
        editButton.contentHorizontalAlignment = .right
        editButton.contentVerticalAlignment = .bottom
        editButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        commentHead.textColor = .white
        commentHead.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(28))!
        commentHead.margins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        [commentHead, editButton].forEach { label in
            stackView.addArrangedSubview(label)
        }
        setupCardParts([stackView])
    }
    
    func setText(_ text: String) {
        commentHead.text = text
    }
}


class CommentTable: CardPartsViewController, CardPartTableViewDelegate, CustomMarginCardTrait, TransparentCardTrait {
    
    func customMargin() -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    var viewModel: DefectDetailViewModel!
    
    let commentTable = CardPartTableView()
    let emptyText = CardPartTextView(type: .normal)
    let emptyView = UIView()
    let messageLabel = UILabel()
    
    typealias CommentSection = AnimatableSectionModel<String, CommentStruct>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyText.text = "No Comment found"
        emptyText.textColor = .black
        emptyText.backgroundColor = UIColor.lightBlueCity.withAlphaComponent(0.5)
        emptyText.textAlignment = .center
        emptyText.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
        
        commentTable.tableView.allowsMultipleSelection = false
        commentTable.tableView.dataSource = nil
        commentTable.delegate = self
        commentTable.tableView.separatorStyle = .none
        commentTable.tableView.backgroundColor = UIColor.lightBlueCity.withAlphaComponent(0.5)
        commentTable.tableView.estimatedRowHeight = 150
        commentTable.backgroundColor = .clear
        commentTable.tableView.register(CommentCell.self, forCellReuseIdentifier: "CommentCell")
        
        messageLabel.text = "Please Add Comment Data"
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        messageLabel.alpha = 0.5
        messageLabel.sizeToFit()
        emptyView.clipsToBounds = true
        emptyView.addSubview(messageLabel)
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<CommentSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
        viewModel.commentData
            .map { [CommentSection(model: "", items: $0)] }
            .bind(to: commentTable.tableView.rx.items(dataSource: dataSource))
        .disposed(by: bag)
        
        viewModel.state.asObservable().bind(onNext: { [weak self] state in
            
            let width = UIScreen.main.bounds.size.width - 48
            
            if state == .empty {
                self?.emptyView.frame = CGRect(x: 0, y: 0, width: width, height: 138.5)
                self?.commentTable.tableView.tableFooterView = self?.emptyView
            } else {
                self?.emptyView.frame = CGRect(x: 0, y: 0, width: width, height: 1)
                self?.commentTable.tableView.tableFooterView = self?.emptyView
            }
            if let center = self?.emptyView.center {
                self?.messageLabel.center =  center
            }
    
        }).disposed(by: bag)
        
        commentTable.tableView.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            
            guard let model = try? self.commentTable.tableView.rx.model(at: indexPath) as CommentStruct? else { return }
      
            self.viewModel.removeComment(model)
       
        }).disposed(by: bag)
        
        commentTable.tableView.rx.modelSelected(CommentStruct.self)
            .subscribe(onNext: { [unowned self] comment in
                self.viewModel.editComment([comment])
            })
            .disposed(by: bag)
        
        setupCardParts([commentTable])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageLabel.center =  emptyView.center
    }
}


extension CommentTable {
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<CommentSection>.ConfigureCell {
        return {  _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentCell else { return UITableViewCell() }
            cell.selectedBackgroundView = UIView()
            cell.setData(item)
            
            return cell
        }
    }

    private var canEditRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<CommentSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.commentTable.tableView.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    private var canMoveRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<CommentSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return false
        }
    }
}


class CommentCell: UITableViewCell {
    
    let defectLabel = UILabel()
    let dateLabel = UILabel()
    let defectBody = UILabel()
    let mainView = UIView()
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let marginGuide = contentView.layoutMarginsGuide
        backgroundColor = .clear
        mainView.backgroundColor = .white
        mainView.layer.cornerRadius = 10.0
        defectBody.lineBreakMode = .byWordWrapping
        defectBody.numberOfLines = 0
        
        contentView.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor, constant: 5).isActive = true
        mainView.topAnchor.constraint(equalTo: marginGuide.topAnchor, constant: 5).isActive = true
        mainView.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor, constant: -5).isActive = true
        mainView.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor, constant: -5).isActive = true
        
        mainView.addSubview(defectLabel)
        defectLabel.textColor = .black
        defectLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))
        defectLabel.translatesAutoresizingMaskIntoConstraints = false
        defectLabel.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 20).isActive = true
        defectLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 30).isActive = true
        
        mainView.addSubview(dateLabel)
        dateLabel.textColor = .black
        dateLabel.textAlignment = .right
        dateLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -30).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: defectLabel.centerYAnchor).isActive = true
        dateLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        defectLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor).isActive = true
        
        mainView.addSubview(defectBody)
        defectBody.textColor = .black
        defectBody.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(14))
        defectBody.translatesAutoresizingMaskIntoConstraints = false
        defectBody.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 30).isActive = true
        defectBody.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -30).isActive = true
        defectBody.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -20).isActive = true
        defectBody.topAnchor.constraint(equalTo: defectLabel.bottomAnchor, constant: 10).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(_ data: CommentStruct) {
        
        defectLabel.text = data.title
        defectBody.text = data.value
        dateLabel.text = data.timeStamp
        
    }
}


class PhotoTable: CardPartsViewController, CardPartTableViewDelegate, CustomMarginCardTrait, TransparentCardTrait, UIScrollViewDelegate {
    
    func customMargin() -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    var viewModel: DefectDetailViewModel!
    
    let photoTable = CardPartTableView()
    let emptyView = UIView()
    let messageLabel = UILabel()
    
    typealias PhotoSection = AnimatableSectionModel<String, ImageStruct>
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        photoTable.tableView.allowsMultipleSelection = false
        photoTable.tableView.dataSource = nil
        photoTable.delegate = self
        photoTable.tableView.separatorStyle = .none
        photoTable.tableView.backgroundColor = UIColor.lightBlueCity.withAlphaComponent(0.5)
        photoTable.backgroundColor = .clear
        photoTable.tableView.register(PhotoCell.self, forCellReuseIdentifier: "PhotoCell")
        
        messageLabel.text = "Please Add Photo Data"
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        messageLabel.alpha = 0.5
        messageLabel.sizeToFit()
        emptyView.clipsToBounds = true
        emptyView.addSubview(messageLabel)
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<PhotoSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
        viewModel.photoState.asObservable().bind(onNext: { [weak self] state in
            
            let width = UIScreen.main.bounds.size.width - 48
            
            if state == .empty {
                self?.emptyView.frame = CGRect(x: 0, y: 0, width: width, height: 138.5)
                self?.photoTable.tableView.tableFooterView = self?.emptyView
            } else {
                self?.emptyView.frame = CGRect(x: 0, y: 0, width: width, height: 1)
                self?.photoTable.tableView.tableFooterView = self?.emptyView
            }
            if let center = self?.emptyView.center {
                self?.messageLabel.center =  center
            }
    
        }).disposed(by: bag)
        
        viewModel.photoData
            .map { [PhotoSection(model: "", items: $0)] }
            .bind(to: photoTable.tableView.rx.items(dataSource: dataSource))
        .disposed(by: bag)
        
        photoTable.tableView.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            
            guard let model = try? self.photoTable.tableView.rx.model(at: indexPath) as ImageStruct? else { return }
            self.viewModel.removePhoto(model)
                        
        }).disposed(by: bag)
                
        setupCardParts([photoTable])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageLabel.center =  emptyView.center
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        
        if let views = sender.view?.subviews {
            for view in views {
                if let imageView = view as? UIImageView,
                   let window = view.window,
                   let image = imageView.image {
                    
                    let scrollView = UIScrollView()
                    scrollView.delegate = self
                    scrollView.showsVerticalScrollIndicator = true
                    scrollView.flashScrollIndicators()
                    scrollView.alpha = 0
                    scrollView.minimumZoomScale = 1.0
                    scrollView.maximumZoomScale = 10.0
                    scrollView.bounces = false
                    scrollView.isUserInteractionEnabled = true
                    scrollView.bouncesZoom = false
                    scrollView.frame = window.bounds
                    
                    let newImageView = UIImageView(image: image)
                    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissScreen))
                    
                    [scrollView, newImageView].forEach { view in
                        
                        view.translatesAutoresizingMaskIntoConstraints = true
                        view.autoresizingMask = [UIView.AutoresizingMask.flexibleLeftMargin,
                                                 UIView.AutoresizingMask.flexibleRightMargin,
                                                 UIView.AutoresizingMask.flexibleTopMargin,
                                                 UIView.AutoresizingMask.flexibleBottomMargin,
                                                 UIView.AutoresizingMask.flexibleHeight,
                                                 UIView.AutoresizingMask.flexibleWidth] }
                    
                    newImageView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                    newImageView.contentMode = .scaleAspectFit
                    newImageView.frame = scrollView.bounds
                    
                    scrollView.insertSubview(newImageView, at: 0)
                    scrollView.addGestureRecognizer(tap)
                    
                    window.addSubview(scrollView)
                    
                    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                        
                        scrollView.alpha = 1

                    }, completion: nil)
                }
            }
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        guard var scrollViewFrame = scrollView.subviews.first?.frame else { return }
        
        let boundsSize = scrollView.bounds.size
        var frameToCenter = scrollViewFrame

        let widthDiff = boundsSize.width  - frameToCenter.size.width
        let heightDiff = boundsSize.height - frameToCenter.size.height
        frameToCenter.origin.x = (widthDiff  > 0) ? widthDiff  / 2 : 0;
        frameToCenter.origin.y = (heightDiff > 0) ? heightDiff / 2 : 0;

        scrollViewFrame = frameToCenter;
    }
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first
    }
    
    @objc func dismissScreen(_ sender: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {

            sender.view?.alpha = 0
            
        }, completion: {finished in
            
            sender.view?.removeFromSuperview()
            
        })
    }
}


extension PhotoTable {
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<PhotoSection>.ConfigureCell {
        return {  [unowned self] _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else { return UITableViewCell() }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
            cell.setData(item, tap)
            cell.selectedBackgroundView = UIView()
            
            return cell
        }
    }

    private var canEditRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<PhotoSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.photoTable.tableView.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    private var canMoveRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<PhotoSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return false
        }
    }
}


class PhotoCell: UITableViewCell {
    
    private let photoView = UIImageView()
    private let dateLabel = UILabel()
    private let mainView = UIView()
    
    lazy private var progressIndicator : CustomActivityIndicatorView = {
      return CustomActivityIndicatorView(image: nil)
    }()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let marginGuide = contentView.layoutMarginsGuide
        backgroundColor = .clear
        mainView.backgroundColor = .white
        mainView.layer.cornerRadius = 10.0
                
        contentView.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor, constant: 5).isActive = true
        mainView.topAnchor.constraint(equalTo: marginGuide.topAnchor, constant: 5).isActive = true
        mainView.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor, constant: -5).isActive = true
        mainView.bottomAnchor.constraint(equalTo: marginGuide.bottomAnchor, constant: -5).isActive = true
        
        mainView.addSubview(photoView)
        photoView.translatesAutoresizingMaskIntoConstraints = false
        photoView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor).isActive = true
        photoView.widthAnchor.constraint(equalToConstant: 75).isActive = true
        photoView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        photoView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 30).isActive = true
        
        progressIndicator.hidesWhenStopped = true
        photoView.addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.centerYAnchor.constraint(equalTo: photoView.centerYAnchor, constant: -75 / 4).isActive = true
        progressIndicator.centerXAnchor.constraint(equalTo: photoView.centerXAnchor, constant: -75 / 4).isActive = true
        
        mainView.addSubview(dateLabel)
        dateLabel.textColor = .black
        dateLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 150).isActive = true
        dateLabel.centerYAnchor.constraint(equalTo: mainView.centerYAnchor).isActive = true
        dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: mainView.trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
    func setData(_ data: ImageStruct, _ tap: UITapGestureRecognizer) {

        progressIndicator.startAnimating()
        
        let pipeline = DataPipeLine.shared
        dateLabel.text = data.timeStamp
        
        mainView.isUserInteractionEnabled = true
        mainView.addGestureRecognizer(tap)
        
        guard let url = URL(string: data.image) else { return }
        
        let request = DataRequest(url: url, processors: [])
        
        if let image = pipeline.cachedImage(for: request) {
            return display(image)
        }
     
        pipeline.loadImage(with: request) { [weak self] result in
            if case let .success(response) = result {
                self?.display(response.container)
                self?.animateFadeIn()
            }
            else if case let .failure(error) = result {
                print(error)
            }
        }
    }
    
    private func display(_ container: ImageContainer) {
        progressIndicator.stopAnimating()
        photoView.image = container.image
    }
    
    private func animateFadeIn() {
        photoView.alpha = 0
        UIView.animate(withDuration: 0.4) { self.photoView.alpha = 1 }
    }
}
