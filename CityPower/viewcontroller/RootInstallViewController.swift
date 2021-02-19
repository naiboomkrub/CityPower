//
//  RootInstallViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class RootInstallViewController: UINavigationController {
  
    var viewModel: RootInstallViewModel!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    viewModel.installStackActions
        .subscribe(onNext: { [weak self] installStackAction in
        switch installStackAction {
            
        case .set(let viewModels, let animated):
            let viewControllers = viewModels.compactMap { viewController(forViewModel: $0) }
            self?.setViewControllers(viewControllers, animated: animated)
            
        case .push(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            viewController.navigationItem.largeTitleDisplayMode = .never
            self?.pushViewController(viewController, animated: animated)
    
        case .present(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.present(viewController, animated: animated, completion: nil)
        
        case .pop(let animated):
            _ = self?.popViewController(animated: animated)
            
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
