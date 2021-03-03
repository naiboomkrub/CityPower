//
//  SiteListViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 25/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources


class SiteListViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var allSiteTable: UITableView!
    @IBOutlet weak var siteMenuLabel: UILabel!
    
    var viewModel: SiteListViewModel!
    
    typealias SiteAllSection = AnimatableSectionModel<String, SiteGroup>
    
    private let disposeBag = DisposeBag()
    
    private var load: Bool!

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<SiteAllSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .fade,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell)
        
        viewModel.dataSource
            .map { [SiteAllSection(model: "", items: $0)] }
            .bind(to: allSiteTable.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
                
        Observable.zip(allSiteTable.rx.itemSelected, allSiteTable.rx.modelSelected(SiteGroup.self))
            .subscribe(onNext: { [unowned self] index, model in
                
                self.allSiteTable.deselectRow(at: index, animated: true)
                self.viewModel.selectedSite(model)

        }).disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        allSiteTable.separatorStyle = .none
        allSiteTable.rx.setDelegate(self).disposed(by: disposeBag)
                
        siteMenuLabel.text = "Site List"
        siteMenuLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
        allSiteTable.dataSource = nil
        
        load = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.sizeToFit()

        if !load {
            setUpTable()
            load = true
        }
        
        if let navViews = navigationController?.navigationBar.subviews {
            for logo in navViews {
                if let logo = logo as? UIButton {
                    UIView.animate(withDuration: 0.2) {
                        logo.alpha = 0.0
                    }
                }
            }
        }
        
        viewModel.reloadData()
    }
}


extension SiteListViewController {
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<SiteAllSection>.ConfigureCell {
        return {  _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SiteMenuCell", for: indexPath) as? SiteMenuCell else { return UITableViewCell() }

            cell.setData(item)
            
            return cell
        }
    }
}


class SiteMenuCell: UITableViewCell {
    
    @IBOutlet weak var siteMenuView: UIView!
    @IBOutlet weak var siteMenuImage: UIImageView!
    @IBOutlet weak var siteMenuLabel: UILabel!
    
    private var task: DataTask?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.siteMenuView.backgroundColor = . blueCity
        self.siteMenuView.layer.cornerRadius = 10.0

        self.siteMenuLabel.textColor = .white
        self.siteMenuLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
    }

    func setData (_ data: SiteGroup) {

        let pipeline = DataPipeLine.shared

        guard let url = URL(string: data.image), siteMenuImage.image == nil else { return }

        let request = DataRequest(url: url, processors: [ImageProcessors.Resize(size: siteMenuImage.bounds.size)])

        if let image = pipeline.cachedImage(for: request) {
            return display(image)
        }

        task = pipeline.loadImage(with: request) { [weak self] result in
            if case let .success(response) = result {
                self?.display(response.container)
                self?.animateFadeIn()
            }
        }
        siteMenuLabel.text = data.name
    }

    private func display(_ container: ImageContainer) {
        siteMenuImage.image = container.image
    }

    private func animateFadeIn() {
        siteMenuImage.alpha = 0
        UIView.animate(withDuration: 0.4) { self.siteMenuImage.alpha = 1 }
    }
}
