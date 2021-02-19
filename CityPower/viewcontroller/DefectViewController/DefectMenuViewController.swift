//
//  DefectMenuViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/1/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources
import PDFKit


class DefectMenuViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableLabel: UILabel!
    @IBOutlet weak var menuTable: UITableView!
    @IBOutlet weak var tableButton: UIButton!
    
    var viewModel: DefectMenuViewModel!
    var load: Bool!
    
    typealias DefectAllSection = AnimatableSectionModel<String, DefectGroup>
    
    private let logo = UIButton()
    private let disposeBag = DisposeBag()
    
    private var tapBag = DisposeBag()
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //guard let currentCell = tableView.cellForRow(at: indexPath) as? DefectMenuCell else { return }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<DefectAllSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
        viewModel.dataSource
            .map { [DefectAllSection(model: "", items: $0)] }
            .bind(to: menuTable.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        menuTable.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            self.viewModel.removeData(index: indexPath)
            
            //if EventTasks.shared.savedTask.count == 0 {
            //    self.menuTable.setEmptyMessage("Please Insert Task")
            //}
                        
        }).disposed(by: disposeBag)
        
        menuTable.rx.itemMoved
            .subscribe(onNext: { [unowned self] source, destination in
                guard source != destination else { return }
                let item = self.viewModel.dataSource.value[source.row]
                self.viewModel.swapData(index: source, insertIndex: destination, element: item)
            })
            .disposed(by: disposeBag)
        
        menuTable.rx.modelSelected(DefectGroup.self)
            .subscribe(onNext: { [unowned self] task in
                //self.viewModel.editTask(taskClick: [task])
                guard let url = task.url?.absoluteString else { return }
                self.viewModel.planDetail.accept(url)
                self.viewModel.selectedArea()
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        menuTable.separatorStyle = .none
        menuTable.rx.setDelegate(self).disposed(by: disposeBag)
        
        tableLabel.text = "Defect Area"
        tableLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
        tableButton.setTitle("Edit", for: .normal)
        tableButton.setTitleColor(.blueCity, for: .normal)
        tableButton.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!

        menuTable.dataSource = nil
        
        tableButton.rx.tap
            .map { [unowned self] in self.menuTable.isEditing }
            .bind(onNext: { [unowned self] result in
                self.menuTable.setEditing(!result, animated: true)
                if !result { self.tableButton.setTitle("Done", for: .normal) }
                else { self.tableButton.setTitle("Edit", for: .normal) }
            })
            .disposed(by: disposeBag)
        
        load = false
        setUpHeaderButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !load {
            setUpTable()
            load = true
        }
        
        logo.rx.tap.bind(onNext: { [weak self] in
            self?.viewModel.addPlan()
        }).disposed(by: tapBag)
        
        viewModel.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
                
        tapBag = DisposeBag()
    }
    
    private func setUpHeaderButton() {
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .large)
        logo.setImage(UIImage(systemName: "plus", withConfiguration: largeConfig), for: .normal)
        
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        navigationBar.addSubview(logo)
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -25),
                                        logo.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -12.5),
            logo.heightAnchor.constraint(equalToConstant: 30),
            logo.widthAnchor.constraint(equalToConstant: 30)])
    }
}


extension DefectMenuViewController {
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<DefectAllSection>.ConfigureCell {
        return {  _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DefectMenuCell", for: indexPath) as? DefectMenuCell else { return UITableViewCell() }

            cell.setData(item)
            
            return cell
        }
    }

    private var canEditRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<DefectAllSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.menuTable.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    private var canMoveRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<DefectAllSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return true
        }
    }
}


class DefectMenuCell: UITableViewCell {
    
    @IBOutlet weak var planView: UIView!
    @IBOutlet weak var defectPlanLabel: UILabel!
    @IBOutlet weak var pdfImage: UIImageView!
    
    private var task: DataTask?
    
    override func draw(_ rect: CGRect) {
        //thumbnailView.thumbnailSize = CGSize(width: 70, height: 70)
        //thumbnailView.layoutMode = .horizontal
        //thumbnailView.pdfView = pdfView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //guard let path = URL(string: "http://www.africau.edu/images/default/sample.pdf") else { return }
        //if let document = PDFDocument(url: path) {
        //    pdfView.document = document
        //}
        
        //thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        //pdfThumbnail.addSubview(thumbnailView)

        //thumbnailView.leadingAnchor.constraint(equalTo: pdfThumbnail.safeAreaLayoutGuide.leadingAnchor).isActive = true
        //thumbnailView.trailingAnchor.constraint(equalTo: pdfThumbnail.safeAreaLayoutGuide.trailingAnchor).isActive = true
        //thumbnailView.bottomAnchor.constraint(equalTo: pdfThumbnail.safeAreaLayoutGuide.bottomAnchor).isActive = true
        //thumbnailView.heightAnchor.constraint(equalTo: pdfThumbnail.heightAnchor).isActive = true
        
        //thumbnailView.thumbnailSize = CGSize(width: 70, height: 70)
        //thumbnailView.layoutMode = .horizontal
        //thumbnailView.pdfView = pdfView
        
        self.planView.backgroundColor = . blueCity
        self.planView.layer.cornerRadius = 10.0
        
        self.defectPlanLabel.textColor = .white
        self.defectPlanLabel.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
    }
    
    func setData (_ data: DefectGroup) {
        
        let pipeline = DataPipeLine.shared
        
        guard let url = data.url else { return }
        
        let request = DataRequest(url: url, processors: [ImageProcessors.Resize(size: pdfImage.bounds.size)])
        
        if let image = pipeline.cachedImage(for: request) {
            return display(image)
        }
     
        task = pipeline.loadImage(with: request) { [weak self] result in
            if case let .success(response) = result {
                self?.display(response.container)
                self?.animateFadeIn()
            }
        }
        defectPlanLabel.text = data.defectTitle
    }
    
    private func display(_ container: ImageContainer) {
        pdfImage.image = container.image
    }
    
    private func animateFadeIn() {
        pdfImage.alpha = 0
        UIView.animate(withDuration: 0.4) { self.pdfImage.alpha = 1 }
    }
}
