//
//  RootLessonViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class RootDefectViewController: UINavigationController {
  
    var viewModel: RootDefectViewModel!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.defectStackActions
        .subscribe(onNext: { [weak self] defectStackAction in
        switch defectStackAction {
            
        case .set(let viewModels, let animated):
            let viewControllers = viewModels.compactMap { viewController(forViewModel: $0) }
            self?.setViewControllers(viewControllers, animated: animated)
            
        case .push(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.pushViewController(viewController, animated: animated)
    
        case .present(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.present(viewController, animated: animated, completion: nil)
            
        case .present1(let viewController, let animated):
            self?.pushViewController(viewController, animated: animated)
        
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
