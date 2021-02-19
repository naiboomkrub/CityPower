//
//  RootScheduleController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class RootScheduleController: UINavigationController {
  
    var viewModel: RootScheduleViewModel!
    var scheduleVC: ScheduleController!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    viewModel.scheduleStackActions
        .subscribe(onNext: { [weak self] scheduleStackAction in
        switch scheduleStackAction {
            
        case .set(let viewModels, let animated):
            let viewControllers = viewModels.compactMap { viewController(forViewModel: $0) }
            if let vc = viewControllers as? [ScheduleController] {
                self?.scheduleVC = vc[0]
            }
            self?.setViewControllers(viewControllers, animated: animated)
            
        case .push(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.pushViewController(viewController, animated: animated)
    
        case .present(let viewModel, let animated):
            guard let viewController = viewController(forViewModel: viewModel) else { return }
            self?.present(viewController, animated: animated, completion: nil)
        
        case .pop(let animated):
            _ = self?.popViewController(animated: animated)
            
        case .dismiss(let animated):
            _ = self?.dismiss(animated: animated)
            
            self?.scheduleVC.taskTable.reloadData()
            self?.scheduleVC.calendar.reloadData()
            self?.scheduleVC.viewModel.changeDate()
            if self?.scheduleVC.viewModel.tempData.count != 0 {
                self?.scheduleVC.scheduleTable.restore()
            }
            
        case .dismiss2(let animated):
            _ = self?.dismiss(animated: animated)
            
            self?.scheduleVC.calendar.reloadData()
            if EventTasks.shared.savedTask.count != 0 {
                self?.scheduleVC.taskTable.restore()
            }
            
        case .presentui(let message):
            let alert = UIAlertController(title: "Warning", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
            
        }).disposed(by: disposeBag)
    }
}
