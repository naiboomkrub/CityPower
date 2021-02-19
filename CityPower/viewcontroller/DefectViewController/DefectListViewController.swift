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
    @IBOutlet weak var planLabel: UILabel!
    @IBOutlet weak var planPicture: UIImageView!
    @IBOutlet weak var expandButtonView: UIView!
    @IBOutlet weak var filterView: UIView!
    
    var viewModel: DefectListViewModel!
    
    private var load: Bool = false
    private var annotationsToDelete = [UIView]()
    private var count = 1
    private var tapBag = DisposeBag()
    
    private let pan = LayerMove()
    private let disposeBag = DisposeBag()
    private let progressIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    
    typealias DefectListSection = AnimatableSectionModel<String, DefectDetail>
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<DefectListSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
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
        
        listTable.rx.itemMoved
            .subscribe(onNext: { [unowned self] source, destination in
                guard source != destination else { return }
                let item = self.viewModel.dataSource.value[source.row]
                self.viewModel.swapData(index: source, insertIndex: destination, element: item)
            })
            .disposed(by: disposeBag)
        
        Observable.zip(listTable.rx.itemSelected, listTable.rx.modelSelected(DefectDetail.self))
            .subscribe(onNext: { [unowned self] index, model in
                
                self.listTable.deselectRow(at: index, animated: true)
                self.viewModel.selectedDefect(model, index)
            })
            .disposed(by: disposeBag)
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let segmented = CustomSegmentedControl(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50), buttonTitle: ["Defect","Plan"])
        segmented.backgroundColor = .clear
        segmented.delegate = self

        parentSwapView.addSubview(segmented)
        
        confirmButton.addTarget(self, action: #selector(completeTask), for: .touchUpInside)
        listTable.separatorStyle = .none
        listTable.rx.setDelegate(self).disposed(by: disposeBag)
        
        listLabel.text = "Defect Selection"
        listLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
        planLabel.text = "Plan Label"
        planLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
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
        
        let tempView = TemView(frame: CGRect(x: 50, y: 50, width: 50, height: 70))
        tempView.backgroundColor = .clear
        planPicture.addSubview(tempView)
        planPicture.isUserInteractionEnabled = true
        planPicture.addGestureRecognizer(tap)
        
        viewModel.imageName.subscribe(onNext: { [weak self] image in
            
            guard let url = URL(string: image) else { return }

            let pipeline = DataPipeLine.shared
            let request = DataRequest(url: url, processors: [])

            if let container = pipeline.cachedImage(for: request) {
                self?.planPicture.image = container.image
                return
            }
            
            pipeline.loadImage(with: request) { [weak self] result in
                if case let .success(response) = result {
                    self?.planPicture.image = response.image
                }
            }

        }).disposed(by: disposeBag)
        
        listTable.dataSource = nil
        
        editButton.rx.tap
            .map { [unowned self] in self.listTable.isEditing }
            .bind(onNext: { [unowned self] result in
                self.listTable.setEditing(!result, animated: true)
                if !result { self.editButton.setTitle("Done", for: .normal) }
                else { self.editButton.setTitle("Edit", for: .normal) }
            })
            .disposed(by: disposeBag)
    
        setUpFilterView()
    }
    
    deinit {
        DefectDetails.shared.stopListening()
        DefectDetails.shared.loadDefect()
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
                    
                    var positionTag: [String: CGPoint] = [:]
                    
                    guard let subViews = self?.planPicture.subviews,
                          let imageSize = self?.planPicture.image?.size,
                          let width = self?.planPicture.bounds.width, let height = self?.planPicture.bounds.height else { return }
                    
                    let aspectWidth  = width / imageSize.width
                    let aspectHeight = height / imageSize.height
                    let f = min(aspectWidth, aspectHeight)
                    
                    for view in subViews {
                        if let tem = view as? TemView, let label = tem.labelNum.text {
                            
                            var imagePoint = tem.frame.origin
                            
                            imagePoint.y -= (height - imageSize.height * f) / 2.0
                            imagePoint.x -= (width - imageSize.width * f) / 2.0
                            imagePoint.x /= f
                            imagePoint.y /= f
                            positionTag[label] = imagePoint
                        }
                    }
                    self?.viewModel.positionTag.accept(positionTag)
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
            let nweAspectHeight = newImageView.bounds.height / image.size.height
            let fNew = min(newAspectWidth, nweAspectHeight)
            
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
        planPicture.addGestureRecognizer(pan)
    }
        
    func didTapButtonWithLoc(_ center: CGPoint) {
        planPicture.removeGesture()
        let tap = UITapGestureRecognizer(target: self, action: #selector(addAnnotation))
        tap.delegate = self
        planPicture.addGestureRecognizer(tap)
    }
    
    func didTapDeleteWithLoc(_ center: CGPoint) {
        planPicture.removeGesture()
        let tap = UITapGestureRecognizer(target: self, action: #selector(deleteAnnotation))
        tap.delegate = self
        planPicture.addGestureRecognizer(tap)
    }
    
    func didCollapse(_ willCollapse: Bool) {
        if !willCollapse {
            planPicture.removeGesture()
            
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
    
    private var canMoveRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<DefectListSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return true
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
        
        let tempView = TemView()
        tempView.setText("\(count)")
        tempView.bounds.size = CGSize(width: 50, height: 70)
        tempView.frame.origin = CGPoint(x: position.x - 25, y: position.y - 35)
        tempView.backgroundColor = .clear
        count += 1
        planPicture.addSubview(tempView)
    }
    
    @objc func completeTask() {
        
        if !annotationsToDelete.isEmpty {
            for view in annotationsToDelete {
                view.removeFromSuperview()
            }
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
        
        defectDes.text = data.defectNumber
        defectLabel.text = data.defectTitle
        dueDate.text = "Due : \(data.timeStamp)"
        
        if data.finish {
            doneState.setImage(UIImage(systemName: "checkmark", withConfiguration: largeConfig), for: .normal)
            doneState.tintColor = .green
        }
        else {
            doneState.setImage(UIImage(systemName: "xmark",  withConfiguration: largeConfig), for: .normal)
            doneState.tintColor = .red
        }
        switch data.system {
        case "General":
            defectListCell.backgroundColor = .general
        default:
            defectListCell.backgroundColor = .blueCity
        }
    
    }
    
}
