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


class DefectMenuViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableLabel: UILabel!
    @IBOutlet weak var menuTable: UITableView!
    @IBOutlet weak var tableButton: UIButton!
    @IBOutlet weak var searchArea: UISearchBar!
    
    var viewModel: DefectMenuViewModel!
    
    typealias DefectAllSection = AnimatableSectionModel<String, DefectGroup>
    
    private let logo = UIButton()
    private let disposeBag = DisposeBag()
    
    private var load: Bool!
    private var tapBag = DisposeBag()

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func filteredSectionModels(sectionModels: [DefectAllSection], filter: String) -> [DefectAllSection] {
        guard !filter.isEmpty else { return sectionModels }
        return sectionModels.map {
            AnimatableSectionModel(model: $0.model,
                                   items: $0.items.filter { $0.planTitle.lowercased().range(of: filter.lowercased(), options: .anchored) != nil })
        }
    }
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<DefectAllSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
        let searchTerm = searchArea.rx.text.orEmpty
            .debounce(.microseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged().filter { !$0.isEmpty }
        
        Observable.combineLatest(viewModel.dataSource, searchTerm)
            .map { [unowned self] in self.filteredSectionModels(sectionModels: [DefectAllSection(model: "", items: $0.0)], filter: $0.1) }
            .bind(to: menuTable.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        menuTable.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            self.viewModel.removeData(index: indexPath)
            
            //if EventTasks.shared.savedTask.count == 0 {
            //    self.menuTable.setEmptyMessage("Please Insert Task")
            //}
                        
        }).disposed(by: disposeBag)
        
        Observable.zip(menuTable.rx.itemSelected, menuTable.rx.modelSelected(DefectGroup.self))
            .subscribe(onNext: { [unowned self] index, model in
                self.menuTable.deselectRow(at: index, animated: true)
                DefectDetails.shared.currentGroup = model.planTitle
                DefectDetails.shared.loadList(model.planTitle)
            
                self.viewModel.planDetail.accept(model.planUrl)
                self.viewModel.selectedArea()
        }).disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHideKeyboardOnTap()
        
        menuTable.separatorStyle = .none
        menuTable.rx.setDelegate(self).disposed(by: disposeBag)
        
        searchArea.backgroundImage = UIImage()
        
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
                                        logo.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -7.5),
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
            return false
        }
    }
}


class DefectMenuCell: UITableViewCell {
    
    @IBOutlet weak var planView: UIView!
    @IBOutlet weak var defectPlanLabel: UILabel!
    @IBOutlet weak var pdfImage: UIImageView!
    
    lazy private var progressIndicator : CustomActivityIndicatorView = {
      return CustomActivityIndicatorView(image: nil)
    }()
    
    private var task: DataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        self.planView.backgroundColor = . blueCity
        self.planView.layer.cornerRadius = 10.0
        
        progressIndicator.hidesWhenStopped = true
        pdfImage.addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.centerYAnchor.constraint(equalTo: pdfImage.centerYAnchor, constant: -75 / 4).isActive = true
        progressIndicator.centerXAnchor.constraint(equalTo: pdfImage.centerXAnchor, constant: -75 / 4).isActive = true
        
        self.defectPlanLabel.textColor = .white
        self.defectPlanLabel.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        pdfImage.image = nil
    }
    
    func setData (_ data: DefectGroup) {
        
        progressIndicator.startAnimating()
        
        defectPlanLabel.text = data.planTitle
        
        guard let url = URL(string: data.planUrl), pdfImage.image == nil else { return progressIndicator.stopAnimating() }
        
        let pipeline = DataPipeLine.shared
        
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
    }
    
    private func display(_ container: ImageContainer) {
        progressIndicator.stopAnimating()
        pdfImage.image = container.image
    }
    
    private func animateFadeIn() {
        pdfImage.alpha = 0
        UIView.animate(withDuration: 0.4) { self.pdfImage.alpha = 1 }
    }
}
