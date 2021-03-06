//
//  DefectListViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources
import AVFoundation


class DefectListViewController: UIViewController, UITableViewDelegate, UIScrollViewDelegate  {
    
    @IBOutlet weak var parentSwapView: UIView!
    @IBOutlet weak var planView: UIView!
    @IBOutlet weak var listView: UIView!
    @IBOutlet weak var listLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var listTable: UITableView!
    @IBOutlet weak var planPicture: UIImageView!
    @IBOutlet weak var expandButtonView: UIView!
    @IBOutlet weak var filterView: UIView!
    @IBOutlet weak var planFilter: UIView!
    @IBOutlet weak var filterScroll: UIScrollView!
    @IBOutlet weak var heightScroll: NSLayoutConstraint!
    
    var viewModel: DefectListViewModel!
    
    private var load: Bool = false
    private var annotationsToDelete = [UIView]()
    private var numList = [Int]()
    private var tapBag = DisposeBag()
    private var allTem: [TemView]? = []
    
    private let pan = LayerMove()
    private let disposeBag = DisposeBag()
    private let progressIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    
    typealias DefectListSection = AnimatableSectionModel<String, DefectDetail>
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170
    }
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<DefectListSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .fade,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .fade),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath)
        
        viewModel.dataSource
            .map { [DefectListSection(model: "", items: $0)] }
            .bind(to: listTable.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        listTable.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            self.viewModel.removeData(index: indexPath)
            
            //if EventTasks.shared.savedTask.count == 0 {
            //    self.menuTable.setEmptyMessage("Please Insert Task")
            //}
                        
        }).disposed(by: disposeBag)
        
        Observable.zip(listTable.rx.itemSelected, listTable.rx.modelSelected(DefectDetail.self))
            .subscribe(onNext: { [unowned self] index, model in
                self.listTable.deselectRow(at: index, animated: true)
                self.viewModel.selectedDefect(model)
        }).disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let segmented = CustomSegmentedControl(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50), buttonTitle: ["Defect","Plan"])
        segmented.backgroundColor = .clear
        segmented.delegate = self
        parentSwapView.addSubview(segmented)
        
        navigationItem.largeTitleDisplayMode = .never
        
        confirmButton.addTarget(self, action: #selector(completeTask), for: .touchUpInside)
        confirmButton.alpha = 0.0
        confirmButton.setTitle("Delete", for: .normal)
        confirmButton.setTitleColor(.blueCity, for: .normal)
        confirmButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        listTable.dataSource = nil
        listTable.separatorStyle = .none
        listTable.rx.setDelegate(self).disposed(by: disposeBag)
        
        listLabel.text = DefectDetails.shared.currentGroup
        listLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
        progressIndicator.hidesWhenStopped = true
        progressIndicator.color = UIColor(red: 162.0 / 255, green: 162.0 / 255, blue: 162.0 / 255, alpha: 1)
        viewModel.progressSpin.asObservable().bind(to: progressIndicator.rx.isAnimating).disposed(by: disposeBag)
        view.addSubview(progressIndicator)
        
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.blueCity, for: .normal)
        editButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        let buttonExpand = ButtonPanelView()
        buttonExpand.delegate = self
        expandButtonView.backgroundColor = .clear
        expandButtonView.addSubview(buttonExpand)
        
        buttonExpand.centerYAnchor.constraint(equalTo: expandButtonView.centerYAnchor).isActive = true
        buttonExpand.rightAnchor.constraint(equalTo: expandButtonView.rightAnchor).isActive = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
        
        planPicture.isUserInteractionEnabled = true
        planPicture.addGestureRecognizer(tap)
                
        Observable.combineLatest(viewModel.imagePoint, viewModel.imageName)
        .subscribe(onNext: { [weak self] point, image in
            
            guard let url = URL(string: image) else { return }
            
            if self?.planPicture.image == nil {
                
                let pipeline = DataPipeLine.shared
                let request = DataRequest(url: url, processors: [])
                
                if let container = pipeline.cachedImage(for: request) {
                    
                    DispatchQueue.main.async {
                        
                        self?.planPicture.image = container.image
                        
                        var newSize = CGSize()
                        
                        if UIScreen.main.scale == 3 {
                            newSize.width = container.image.size.width * 1.5
                            newSize.height = container.image.size.height * 1.5
                        } else {
                            newSize = container.image.size
                        }

                        if let viewSize = self?.planPicture.bounds.size {
                            
                            let newAspectWidth  = viewSize.width / newSize.width
                            let newAspectHeight = viewSize.height / newSize.height
                            let fNew = min(newAspectWidth, newAspectHeight)
                            
                            self?.allTem?.removeAll()
                            
                            for subPoint in point {
                                
                                if var refPoint = subPoint.defectPosition {
                                    refPoint.y *= fNew
                                    refPoint.x *= fNew
                                    refPoint.x += (viewSize.width - newSize.width * fNew) / 2.0
                                    refPoint.y += (viewSize.height - newSize.height * fNew) / 2.0
                                    
                                    let tempView = TemView()
                                    tempView.setModel(subPoint)
                                    tempView.bounds.size = CGSize(width: 50, height: 70)
                                    tempView.frame.origin = refPoint
                                    tempView.backgroundColor = .clear
                                    
                                    if let tag = Int(subPoint.pointNum) {
                                        self?.numList.append(tag)
                                    }
                                    self?.planPicture.addSubview(tempView)
                                    self?.allTem?.append(tempView)
                                }
                            }
                        }
                    }
                    return
                }
                
                pipeline.loadImage(with: request) { [weak self] result in
                    if case let .success(response) = result {
              
                        self?.planPicture.image = response.image
                        
                        var newSize = CGSize()
                        
                        if UIScreen.main.scale == 3 {
                            newSize.width = response.image.size.width * 1.5
                            newSize.height = response.image.size.height * 1.5
                        } else {
                            newSize = response.image.size
                        }
                        
                        if let viewSize = self?.planPicture.bounds.size {
                            let newAspectWidth  = viewSize.width / newSize.width
                            let newAspectHeight = viewSize.height / newSize.height
                            let fNew = min(newAspectWidth, newAspectHeight)
                            
                            self?.allTem?.removeAll()
                            
                            for subPoint in point {
                                
                                if var refPoint = subPoint.defectPosition {
                                    refPoint.y *= fNew
                                    refPoint.x *= fNew
                                    refPoint.x += (viewSize.width - newSize.width * fNew) / 2.0
                                    refPoint.y += (viewSize.height - newSize.height * fNew) / 2.0
                                    
                                    let tempView = TemView()
                                    tempView.setModel(subPoint)
                                    tempView.bounds.size = CGSize(width: 50, height: 70)
                                    tempView.frame.origin = refPoint
                                    tempView.backgroundColor = .clear
                                    
                                    if let tag = Int(subPoint.pointNum) {
                                        self?.numList.append(tag)
                                    }
                                    self?.planPicture.addSubview(tempView)
                                    self?.allTem?.append(tempView)
                                }
                            }
                        }
                    }
                }
            } else {

                guard self?.allTem?.compactMap({ $0.imageModel }) != point else { return }
                
                self?.allTem?.removeAll()
                if let subViews = self?.planPicture.subviews {
                    for view in subViews {
                        if let view = view as? TemView, let model = view.imageModel {
                            for subPoint in point {
                                if model.pointNum == subPoint.pointNum {
                                    view.imageModel = subPoint
                                    self?.allTem?.append(view)
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }).disposed(by: disposeBag)
        
        viewModel.temFilter.subscribe(onNext: { [weak self] state in
            
            guard let allTem = self?.allTem else { return }
            
            switch state {
            case .All:
                UIView.animate(withDuration: 0.2, animations: {
                    allTem.forEach { $0.alpha = 1.0 }
                    self?.expandButtonView.alpha = 0.0
                })
            case .Empty:
                UIView.animate(withDuration: 0.2, animations: {
                    allTem.forEach { $0.alpha = 0.0 }
                    self?.expandButtonView.alpha = 1.0
                })
            case .NotChose:
                UIView.animate(withDuration: 0.2, animations:
                                {allTem.forEach {
                                    if let model = $0.imageModel , model.selected { $0.alpha = 0.0 }
                                    else { $0.alpha = 1.0 }}
                                    self?.expandButtonView.alpha = 1.0
                                })
            case .General:
                UIView.animate(withDuration: 0.2, animations:
                                {allTem.forEach {
                                    if let model = $0.imageModel , model.system == "General" { $0.alpha = 1.0 } else { $0.alpha = 0.0 }}
                                    self?.expandButtonView.alpha = 0.0
                                })
            case .Electrical:
                UIView.animate(withDuration: 0.2, animations:
                                {allTem.forEach {
                                    if let model = $0.imageModel , model.system == "Electrical" { $0.alpha = 1.0 } else { $0.alpha = 0.0 }}
                                    self?.expandButtonView.alpha = 0.0
                                })
            case .Sanitary:
                UIView.animate(withDuration: 0.2, animations:
                                {allTem.forEach {
                                    if let model = $0.imageModel , model.system == "Sanitary" { $0.alpha = 1.0 } else { $0.alpha = 0.0 }}
                                    self?.expandButtonView.alpha = 0.0
                                })
            case .Mechanical:
                UIView.animate(withDuration: 0.2, animations:
                                {allTem.forEach {
                                    if let model = $0.imageModel , model.system == "Mechanical" { $0.alpha = 1.0 } else { $0.alpha = 0.0 }}
                                    self?.expandButtonView.alpha = 0.0
                                })
            }
        }).disposed(by: disposeBag)
        
        editButton.rx.tap
            .map { [unowned self] in self.listTable.isEditing }
            .bind(onNext: { [unowned self] result in
                self.listTable.setEditing(!result, animated: true)
                if !result { self.editButton.setTitle("Done", for: .normal) }
                else { self.editButton.setTitle("Edit", for: .normal) }
            }).disposed(by: disposeBag)
    
        setUpFilterView()
        setUpPlanFilter()
    }
    
    deinit {
        DefectDetails.shared.stopListListening()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DefectDetails.shared.currentIndex = nil
        progressIndicator.center = view.center
        
        if !load {
            setUpTable()
            load = true
        }
        setUpHeaderButton()
        viewModel.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
                
        tapBag = DisposeBag()
    }
    
    private func setUpFilterView() {
        
        let filterText = ["General", "Electrical", "Sanitary", "Mechanical"]
        var xIncrement = CGFloat(15.0)
        var lastButton: UIButton?
        
        for text in filterText {
            let labelText = UIButton()
            labelText.setTitle(text, for: .normal)
            labelText.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(14))
            labelText.layer.cornerRadius = 15.0
            
            if text == viewModel.filter {
                labelText.backgroundColor = .Gray6
                lastButton = labelText
            } else {
                labelText.backgroundColor = .clear
            }
            
            labelText.setTitleColor(.black, for: .normal)
            labelText.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
            labelText.sizeToFit()
            labelText.frame.origin = CGPoint(x: xIncrement, y: 10)
            xIncrement += labelText.bounds.size.width
            
            labelText.rx.tap.bind(onNext: { [weak self] in
                guard let text = labelText.titleLabel?.text else { return }
                
                labelText.backgroundColor = .Gray6
                if let button = lastButton, button != labelText {
                    button.backgroundColor = .clear
                    lastButton = labelText
                }
                if text != self?.viewModel.filter {
                    self?.viewModel.filter = text
                    self?.viewModel.reloadData()
                }
            }).disposed(by: disposeBag)
            
            filterView.addSubview(labelText)
        }
    }
    
    private func setUpPlanFilter() {
        
        let filterText = ["All", "Empty", "Not Chose", "General","Electrical", "Sanitary", "Mechanical"]
        
        var xIncrement = CGFloat(15.0)
        var lastButton: UIButton?
        
        for text in filterText {
            let labelText = UIButton()
            labelText.setTitle(text, for: .normal)
            labelText.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(14))
            labelText.layer.cornerRadius = 15.0
            
            if text == "All" {
                labelText.backgroundColor = .Gray6
                lastButton = labelText
            } else {
                labelText.backgroundColor = .clear
            }
            
            labelText.setTitleColor(.black, for: .normal)
            labelText.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
            labelText.sizeToFit()
            labelText.frame.origin = CGPoint(x: xIncrement, y: 10)
            xIncrement += labelText.bounds.size.width
            
            labelText.rx.tap.bind(onNext: { [weak self] in
                guard let text = labelText.titleLabel?.text else { return }
                
                labelText.backgroundColor = .Gray6
                if let button = lastButton, button != labelText {
                    button.backgroundColor = .clear
                    lastButton = labelText
                }
                
                switch text {
                case "All":
                    self?.viewModel.temFilter.accept(PointState.All)
                case "Empty":
                    self?.viewModel.temFilter.accept(PointState.Empty)
                case "Not Chose":
                    self?.viewModel.temFilter.accept(PointState.NotChose)
                case "General":
                    self?.viewModel.temFilter.accept(PointState.General)
                case "Electrical":
                    self?.viewModel.temFilter.accept(PointState.Electrical)
                case "Sanitary":
                    self?.viewModel.temFilter.accept(PointState.Sanitary)
                case "Mechanical":
                    self?.viewModel.temFilter.accept(PointState.Mechanical)
                default:
                    self?.viewModel.temFilter.accept(PointState.All)
                }
            }).disposed(by: disposeBag)
            
            planFilter.addSubview(labelText)
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            heightScroll.constant = xIncrement + 70 - filterScroll.bounds.width
        }
    }
    
    private func setUpHeaderButton() {
        
        guard let navViews = self.navigationController?.navigationBar.subviews else { return }
        
        for logo in navViews {
            if let logo = logo as? UIButton {
                
                if logo.alpha == 0 {
                    UIView.animate(withDuration: 0.2) {
                        logo.alpha = 1.0
                    }
                }
        
                logo.rx.tap.bind(onNext: { [weak self] in
                    
                    var positionModel: [ImagePosition] = []
                    
                    guard let subViews = self?.planPicture.subviews,
                          let imageSize = self?.planPicture.image?.size,
                          let width = self?.planPicture.bounds.width, let height = self?.planPicture.bounds.height else { return }
                    
                    var newSize = CGSize()
                    
                    if UIScreen.main.scale == 3 {
                        newSize.width = imageSize.width * 1.5
                        newSize.height = imageSize.height * 1.5
                    } else {
                        newSize = imageSize
                    }
                    
                    let aspectWidth  = width / newSize.width
                    let aspectHeight = height / newSize.height
                    let f = min(aspectWidth, aspectHeight)
                    
                    for view in subViews {
                        if let tem = view as? TemView, let model = tem.imageModel {
                            
                            var imagePoint = tem.frame.origin
                            
                            imagePoint.y -= (height - newSize.height * f) / 2.0
                            imagePoint.x -= (width - newSize.width * f) / 2.0
                            imagePoint.x /= f
                            imagePoint.y /= f
                            positionModel.append(model)
                        }
                    }
                    self?.viewModel.positionTag.accept(positionModel)
                    self?.viewModel.addDefect()
                    
                }).disposed(by: tapBag)
            }
        }
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        
        if let imageView = sender.view as? UIImageView,
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
                    
            let aspectWidth  = imageView.bounds.width / image.size.width
            let aspectHeight = imageView.bounds.height / image.size.height
            let f = min(aspectWidth, aspectHeight)
            
            let newAspectWidth  = newImageView.bounds.width / image.size.width
            let newAspectHeight = newImageView.bounds.height / image.size.height
            let fNew = min(newAspectWidth, newAspectHeight)
            
            for subView in imageView.subviews {
                if let subView = subView as? TemView,
                   let text = subView.labelNum.text {
                    
                    var imagePoint = subView.frame.origin
                    
                    imagePoint.y -= (imageView.bounds.height - image.size.height * f) / 2.0
                    imagePoint.x -= (imageView.bounds.width - image.size.width * f) / 2.0
                    imagePoint.x /= f
                    imagePoint.y /= f
                    
                    var newImagePoint = imagePoint

                    newImagePoint.y *= fNew
                    newImagePoint.x *= fNew
                    newImagePoint.x += (newImageView.bounds.width - image.size.width * fNew) / 2.0
                    newImagePoint.y += (newImageView.bounds.height - image.size.height * fNew) / 2.0
                    
                    let newTem = TemView(frame: CGRect(origin: newImagePoint, size: CGSize(width: 50, height: 70)))
                    newTem.backgroundColor = .clear
                    newTem.setText(text)
                    newTem.alpha = subView.alpha
                    newImageView.addSubview(newTem)
                }
            }
                        
            window.addSubview(scrollView)
                    
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
                        
                scrollView.alpha = 1

            }, completion: nil)
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


extension DefectListViewController: ButtonPanelDelegate {
    
    func didTapEditWithLoc(_ center: CGPoint) {
        planPicture.removeGesture()
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.confirmButton.alpha = 0.0
        })
        
        for view in annotationsToDelete {
            view.layer.borderWidth = 0.0
        }
        annotationsToDelete.removeAll()
        
        planPicture.addGestureRecognizer(pan)
    }
        
    func didTapButtonWithLoc(_ center: CGPoint) {
        planPicture.removeGesture()
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.confirmButton.alpha = 0.0
        })
        
        for view in annotationsToDelete {
            view.layer.borderWidth = 0.0
        }
        annotationsToDelete.removeAll()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(addAnnotation))
        tap.delegate = self
        planPicture.addGestureRecognizer(tap)
    }
    
    func didTapDeleteWithLoc(_ center: CGPoint) {
        planPicture.removeGesture()
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.confirmButton.alpha = 1.0
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(deleteAnnotation))
        tap.delegate = self
        planPicture.addGestureRecognizer(tap)
    }
    
    func didCollapse(_ willCollapse: Bool) {
        if !willCollapse {
            planPicture.removeGesture()
            
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.confirmButton.alpha = 0.0
            })
            
            for view in annotationsToDelete {
                view.layer.borderWidth = 0.0
            }
            annotationsToDelete.removeAll()
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
            planPicture.addGestureRecognizer(tap)
        }
    }
}

extension DefectListViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


extension DefectListViewController: CustomSegmentedControlDelegate {
    
    func change(to index: Int) {
        if index == 0 {
            planView.isHidden = true
            listView.isHidden = false
        }
        else {
            planView.isHidden = false
            listView.isHidden = true
        }
    }
}

extension DefectListViewController {
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<DefectListSection>.ConfigureCell {
        return {  _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DefectListCell", for: indexPath) as? DefectListCell else { return UITableViewCell() }

            cell.setData(item)
            
            return cell
        }
    }

    private var canEditRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<DefectListSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.listTable.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    @objc func deleteAnnotation(_ sender: UITapGestureRecognizer) {

        let position = sender.location(in: planPicture)
            
        for view in planPicture.subviews {
            let annotationBound = view.frame
            view.layer.borderColor = UIColor.blueCity.cgColor
            if annotationBound.contains(position) && !annotationsToDelete.contains(view) {
                view.layer.borderWidth = 1.0
                annotationsToDelete.append(view)
            } else if annotationBound.contains(position) {
                view.layer.borderWidth = 0.0
                
                if let index = annotationsToDelete.firstIndex(of: view) {
                    annotationsToDelete.remove(at: index)
                }
            }
        }
    }
    
    @objc func addAnnotation(_ sender: UITapGestureRecognizer) {

        let position = sender.location(in: planPicture)
        let newPosition = CGPoint(x: position.x - 25, y: position.y - 35)
        let tempView = TemView()
        let count = numList.count

        var emptyNum = [Int]()
        var numToUpdate = 0
        
        if count > 0, let max = numList.max() {
            let range = 1...max
            
            for i in range {
                if !numList.contains(i) {
                    emptyNum.append(i)
                }
            }
        }
        
        if !emptyNum.isEmpty {
            numToUpdate = emptyNum[0]
        } else {
            numToUpdate = count + 1
        }
        tempView.bounds.size = CGSize(width: 50, height: 70)
        tempView.frame.origin = newPosition
        tempView.backgroundColor = .clear
        
        if let convertedPoint = convertViewToImagePoint(planPicture, newPosition) {
            let doubleX = round(Double(convertedPoint.x) * 1000) / 1000
            let doubleY = round(Double(convertedPoint.y) * 1000) / 1000
            let model = ImagePosition(x: doubleX, y: doubleY, pointNum: "\(numToUpdate)",
                                      system: "", status: statusDefect.Start.rawValue, selected: false)
            tempView.setModel(model)
            DefectDetails.shared.addPoint(model)
        }
        
        numList.append(numToUpdate)
        planPicture.addSubview(tempView)
        allTem?.append(tempView)
    }
    
    @objc func completeTask() {
        
        if !annotationsToDelete.isEmpty {
            
            var removeSet = [ImagePosition]()
            
            for view in annotationsToDelete {
                
                if let temView = view as? TemView, let text = temView.labelNum.text, let model = temView.imageModel {
                    temView.removeFromSuperview()
                    
                    if let image = planPicture.image {
                        
                        var newSize = CGSize()
                        
                        if UIScreen.main.scale == 3 {
                            newSize.width = image.size.width * 1.5
                            newSize.height = image.size.height * 1.5
                        } else {
                            newSize = image.size
                        }
                        
                        let aspectWidth  = planPicture.bounds.width / newSize.width
                        let aspectHeight = planPicture.bounds.height / newSize.height
                        let f = min(aspectWidth, aspectHeight)
                        
                        var imagePoint = view.frame.origin
                        
                        imagePoint.y -= (planPicture.bounds.height - newSize.height * f) / 2.0
                        imagePoint.x -= (planPicture.bounds.width - newSize.width * f) / 2.0
                        imagePoint.x /= f
                        imagePoint.y /= f
                        
                        numList = numList.filter { $0 != Int(text) }
                        removeSet.append(ImagePosition(x: round(Double(imagePoint.x) * 1000) / 1000,
                                                       y: round(Double(imagePoint.y) * 1000) / 1000, pointNum: text,
                                                       system: model.system, status: model.status, selected: model.selected))
                    }
                }
            }
            DefectDetails.shared.removePoint(removeSet)
        }
    }
}


extension UIImageView {
    
    func removeGesture() {
        if let recognizers = gestureRecognizers {
            for recognizer in recognizers {
                removeGestureRecognizer(recognizer)
            }
        }
    }
}


class DefectListCell: UITableViewCell {
        
    @IBOutlet weak var dueDate: UILabel!
    @IBOutlet weak var defectListCell: UIView!
    @IBOutlet weak var defectLabel: UILabel!
    @IBOutlet weak var defectDes: UILabel!
    @IBOutlet weak var doneState: UIButton!
    
    let titleLabel = UILabel()
    let desLabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        defectListCell.layer.cornerRadius = 15.0
        
        dueDate.textColor = UIColor.white
        defectDes.textColor = UIColor.white
        defectLabel.textColor = UIColor.white
        defectLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))
    
    }
    
    func setData (_ data: DefectDetail) {
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        
        defectDes.text = data.defectTitle
        defectLabel.text = data.defectNumber
        dueDate.text = "Due : \(data.timeStamp)"
        
        if data.status == statusDefect.Finish.rawValue {
            doneState.setImage(UIImage(systemName: "checkmark", withConfiguration: largeConfig), for: .normal)
            doneState.tintColor = .green
        } else if data.status == statusDefect.Ongoing.rawValue {
            doneState.setImage(UIImage(systemName: "arrow.clockwise",  withConfiguration: largeConfig), for: .normal)
            doneState.tintColor = .black
        }
        else {
            doneState.setImage(UIImage(systemName: "xmark",  withConfiguration: largeConfig), for: .normal)
            doneState.tintColor = .red
        }
        switch data.system {
        case "General":
            defectListCell.backgroundColor = .general
        case "Sanitary":
            defectListCell.backgroundColor = .sanitary
        case "Mechanical":
            defectListCell.backgroundColor = .mechincal
        case "Electrical":
            defectListCell.backgroundColor = .electrical
        default:
            defectListCell.backgroundColor = .blueCity
        }
    }
}
