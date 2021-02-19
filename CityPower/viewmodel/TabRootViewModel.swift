//
//  TabRootViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

enum TabStackAction {
    case set(viewModels: [Any], animated: Bool)
    case present(viewModel: Any, animated:Bool)
    case dismiss(animated: Bool)
    case presentui(text: String)
}

class TabRootViewModel {
    
    lazy private(set) var mainMenuViewModel: MainMenuViewModel = {
        EventTasks.shared.loadTask()
        Schedule.shared.loadTask()
        InstallHistories.shared.loadTask()
        DefectDetails.shared.loadDefect()
        
        return self.createMainMenuViewModel()
    }()
    
    lazy private(set) var rootViewModel: RootViewModel = {
        return self.createRootViewModel()
    }()
    
    lazy private(set) var rootDefectViewModel: RootDefectViewModel = {
        return self.createRootDefectViewModel()
    }()
    
    lazy private(set) var rootInstallViewModel: RootInstallViewModel = {
        return self.createRootInstallViewModel()
    }()
    
    lazy private(set) var rootScheduleViewModel: RootScheduleViewModel = {
        return self.createRootScheduleViewModel()
    }()
    
    lazy private(set) var tabStackActions: BehaviorSubject<TabStackAction> = {
        return BehaviorSubject(value: .set(viewModels: [self.mainMenuViewModel, self.rootViewModel, self.rootDefectViewModel, self.rootInstallViewModel, self.rootScheduleViewModel], animated: false))
    }()
    
    private let disposeBag = DisposeBag()
    
    func createRootViewModel() -> RootViewModel  {
    
        let rootViewModel = RootViewModel()
        
        return rootViewModel
    }
    
    func createRootScheduleViewModel() -> RootScheduleViewModel  {
    
        let rootScheduleViewModel = RootScheduleViewModel()
        
        return rootScheduleViewModel
    }
    
    func createRootDefectViewModel() -> RootDefectViewModel  {
    
        let rootDefectViewModel = RootDefectViewModel()
        
        return rootDefectViewModel
    }

    func createMainMenuViewModel() -> MainMenuViewModel  {
    
        let mainMenuViewModel  = MainMenuViewModel()
        
        return mainMenuViewModel
    }
    
    func createRootInstallViewModel() -> RootInstallViewModel  {
    
        let rootInstallViewModel  = RootInstallViewModel()
        
        return rootInstallViewModel
    }
    
}
