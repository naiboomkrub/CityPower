//
//  RootInstallViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift

    
enum InstallStackAction {
    case set(viewModels: [Any], animated: Bool)
    case push(viewModel: Any, animated: Bool)
    case present(viewModel: Any, animated:Bool)
    case pop(animated: Bool)
    case dismiss(animated: Bool)
    case presentui(text: String)
}

class RootInstallViewModel {
    
    lazy private(set) var installationViewModel: InstallationViewModel = {
        return self.createInstallViewModel()
    }()
    
    lazy private(set) var installContentViewModel: InstallContentViewModel = {
        return self.createInstallContentViewModel()
    }()
    
    lazy private(set) var installHistoryViewModel: InstallHistoryViewModel = {
        return self.createInstallHistoryViewModel()
    }()
    
    lazy private(set) var installStackActions: BehaviorSubject<InstallStackAction> = {
        return BehaviorSubject(value: .set(viewModels: [self.installationViewModel], animated: false))
    }()

    private let disposeBag = DisposeBag()
    
    func createInstallViewModel() -> InstallationViewModel  {
    
        let installViewModel = InstallationViewModel()
        
        installViewModel.selectContentTitle
            .subscribe(onNext: { [weak self] title in
                self?.installContentViewModel.contentTitle.accept(title)
            }).disposed(by: disposeBag)
        
        installViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Content:
                self?.installContentViewModel.loadHistory = false
                self?.content()
            case .History:
                self?.history()
            }
            }).disposed(by: disposeBag)
        
        return installViewModel
    }
    
    func createInstallContentViewModel() -> InstallContentViewModel {
      
        let installContentViewModel = InstallContentViewModel()
                
        installContentViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .EndContent:
                self?.closeContent()
            }
            }).disposed(by: disposeBag)
        
        return installContentViewModel
    }
    
    func createInstallHistoryViewModel() -> InstallHistoryViewModel {
        
        let installHistoryViewModel = InstallHistoryViewModel()
        
        installHistoryViewModel.installHistory
            .subscribe(onNext: { [weak self] history in
                self?.installContentViewModel.installHistory.accept(history)
            }).disposed(by: disposeBag)
      
        installHistoryViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Data:
                self?.installContentViewModel.loadHistory = true
                self?.data()
            }
            }).disposed(by: disposeBag)
        
        return installHistoryViewModel
    }
    
    private func content() {
        self.installStackActions.onNext(.push(viewModel: self.installContentViewModel, animated: true))
    }
    
    private func history() {
        self.installStackActions.onNext(.push(viewModel: self.installHistoryViewModel, animated: true))
    }
    
    private func data() {
        self.installStackActions.onNext(.push(viewModel: self.installContentViewModel, animated: true))
    }
    
    private func closeContent() {
        self.installStackActions.onNext(.pop(animated: true))
    }
}
