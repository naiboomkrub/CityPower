//
//  RootSelectDateViewContoller.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 4/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class RootSelectDateViewContoller: UINavigationController {
  
    var viewModel: RootSelectDateViewModel!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    viewModel.dateStackActions
        .subscribe(onNext: { [weak self] dateStackAction in
        switch dateStackAction {
            
        case .set(let viewModels, let animated):
            let viewControllers = viewModels.compactMap { viewController(forViewModel: $0) }
            self?.setViewControllers(viewControllers, animated: animated)
            
        case .push(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.pushViewController(viewController, animated: animated)
        
        case .pop(let animated):
            _ = self?.popViewController(animated: animated)
            
        case .presentui(let message):
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
            
        }).disposed(by: disposeBag)
    }
}
