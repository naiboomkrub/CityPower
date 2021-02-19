//
//  RootAddDefectViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 10/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
    

enum AddDefectStackAction {
    case set(viewModels: [Any], animated: Bool)
    case push(viewModel: Any, animated: Bool)
    case pop(animated: Bool)
    case presentui(text: String)
}

class RootAddDefectViewModel {
    
    lazy private(set) var addDefectViewModel: AddDefectViewModel = {
        return self.createAddDefectViewModel()
    }()
    
    lazy private(set) var addDefectStackAction: BehaviorSubject<AddDefectStackAction> = {
        return BehaviorSubject(value: .set(viewModels: [self.addDefectViewModel], animated: false))
    }()
    
    enum Event {
        case Save
     }
    
    let events = PublishSubject<Event>()
    let imageLocation = BehaviorRelay(value: "")
    let tagPosition = BehaviorRelay<[String: CGPoint]>(value: [:])
    
    init(_ imageLoc: String, _ pos: [String: CGPoint]) {
        imageLocation.accept(imageLoc)
        tagPosition.accept(pos)
    }
    
    private let disposeBag = DisposeBag()
    
    func createAddDefectViewModel() -> AddDefectViewModel  {
    
        let addDefectViewModel = AddDefectViewModel()
        
        addDefectViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveDefect()
            case .AddLocation:
                self?.addLocation()
            }
            }).disposed(by: disposeBag)
        
        return addDefectViewModel
    }
    
    func createSelectPositionViewModel() -> SelectPositionViewModel  {
    
        let selectPositionViewModel = SelectPositionViewModel()
        selectPositionViewModel.imageName.accept(imageLocation.value)
        selectPositionViewModel.positionDefect.accept(tagPosition.value)
        
        selectPositionViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .SavePosition:
                self?.getPosition()
            }
            }).disposed(by: disposeBag)
        
        selectPositionViewModel.positionSelected
            .subscribe(onNext: { [weak self] loc in
                self?.addDefectViewModel.resultPosition.accept(loc)
            }).disposed(by: disposeBag)
        
        return selectPositionViewModel
    }
    
    private func saveDefect() {
        events.onNext(.Save)
    }
    
    private func addLocation() {
        self.addDefectStackAction.onNext(.push(viewModel: self.createSelectPositionViewModel(), animated: true))
    }
    
    private func getPosition() {
        self.addDefectStackAction.onNext(.pop(animated: true))
    }
    
}
