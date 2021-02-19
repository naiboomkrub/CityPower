//
//  RootSelectDateViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 4/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
    
enum DateStackAction {
    case set(viewModels: [Any], animated: Bool)
    case push(viewModel: Any, animated: Bool)
    case pop(animated: Bool)
    case presentui(text: String)
}

class RootSelectDateViewModel {
    
    lazy private(set) var addDateViewModel: AddDateViewModel = {
        return self.createAddDateViewModel()
    }()
    
    lazy private(set) var dateStackActions: BehaviorSubject<DateStackAction> = {
        return BehaviorSubject(value: .set(viewModels: [self.addDateViewModel], animated: false))
    }()
    
    enum Event {
        case Save
     }
    
    let events = PublishSubject<Event>()
    let taskDate = BehaviorRelay(value: "")
    
    private let disposeBag = DisposeBag()
    
    init(date: String) { taskDate.accept(date) }
    
    func createAddDateViewModel() -> AddDateViewModel  {
    
        let addDateViewModel = AddDateViewModel(date: self.taskDate.value)
        
        addDateViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveTask()
            case .AddTask:
                self?.addTask()
            }
            }).disposed(by: disposeBag)
        
        return addDateViewModel
    }
    
    func createSelecTaskViewModel() -> SelectTaskViewModel  {
    
        let selectTaskViewModel = SelectTaskViewModel()
        
        selectTaskViewModel.taskSelected
            .subscribe(onNext: { [weak self] task in
                self?.addDateViewModel.taskSelected.accept(task)
            }).disposed(by: disposeBag)
        
        return selectTaskViewModel
    }
    
    private func saveTask() {
        events.onNext(.Save)
    }
    
    private func addTask() {
        self.dateStackActions.onNext(.push(viewModel: self.createSelecTaskViewModel(), animated: true))
    }
    
}
