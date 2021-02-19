//
//  TabRootViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift


class TabRootViewController: UITabBarController, UITabBarControllerDelegate {
    
    var viewModel: TabRootViewModel!
    
    required init?(coder: NSCoder) {
         CardPartsBoomTheme().apply()
         super.init(coder: coder)
     }
    
    private let disposeBag = DisposeBag()
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.tabStackActions
        .subscribe(onNext: { [weak self] tabStackAction in
        switch tabStackAction {
            
        case .set(let viewModels, _):
            let viewControllers = viewModels.compactMap { viewController(forViewModel: $0) }
            self?.viewControllers = viewControllers
            
        case .present(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.present(viewController, animated: animated, completion: nil)

        case .dismiss(let animated):
            _ = self?.dismiss(animated: animated)
            
        case .presentui(let message):
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
            
        }).disposed(by: disposeBag)
    }
}
