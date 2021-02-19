//
//  RootScheduleViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift


enum ScheduleStackAction {
    case set(viewModels: [Any], animated: Bool)
    case push(viewModel: Any, animated: Bool)
    case present(viewModel: Any, animated:Bool)
    case pop(animated: Bool)
    case dismiss(animated: Bool)
    case dismiss2(animated: Bool)
    case presentui(text: String)
}

class RootScheduleViewModel {
    
    lazy private(set) var scheduleViewModel: ScheduleViewModel = {
        return self.createScheduleViewModel()
    }()
    
    lazy private(set) var scheduleStackActions: BehaviorSubject<ScheduleStackAction> = {
        return BehaviorSubject(value: .set(viewModels: [self.scheduleViewModel], animated: false))
    }()
    
    private let disposeBag = DisposeBag()
    
    func createScheduleViewModel() -> ScheduleViewModel {
    
        let scheduleViewModel = ScheduleViewModel()
        
        scheduleViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .AddTask:
                self?.add()
            case .AddDate:
                self?.date()
            case .EditTask:
                guard let info = self?.scheduleViewModel.editInfo.value[0] else { return }
                self?.edit(task: info)
            }
            }).disposed(by: disposeBag)
        
        return scheduleViewModel
    }
    
    func createAddTaskViewModel(_ eventTask: EventTask, _ edit: Bool) -> AddTaskViewModel {
    
        let addTaskViewModel = AddTaskViewModel(eventTask: eventTask, edit: edit)
        
        addTaskViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveTask()
                self?.scheduleViewModel.reloadData()
                self?.scheduleViewModel.changeDate()
            }
            }).disposed(by: disposeBag)
        
        return addTaskViewModel
    }
    
    func createRootDateViewModel() -> RootSelectDateViewModel {
    
        let rootDateViewModel = RootSelectDateViewModel(date: self.scheduleViewModel.date.value)
        
        rootDateViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveSchedule()
            }
            }).disposed(by: disposeBag)
        
        return rootDateViewModel
    }
    
    private func add() {
        self.scheduleStackActions.onNext(.present(viewModel: self.createAddTaskViewModel(EventTask(manDay: "", taskTitle: "", timeStamp: ""), false), animated: true))
    }
    
    private func edit(task: EventTask) {
        self.scheduleStackActions.onNext(.present(viewModel: self.createAddTaskViewModel(task, true), animated: true))
    }
    
    private func date() {
        self.scheduleStackActions.onNext(.present(viewModel: self.createRootDateViewModel(), animated: true))
    }
    
    private func saveTask() {
        self.scheduleStackActions.onNext(.dismiss2(animated: true))
    }
    
    private func saveSchedule() {
        self.scheduleStackActions.onNext(.dismiss(animated: true))
    }
    
}
