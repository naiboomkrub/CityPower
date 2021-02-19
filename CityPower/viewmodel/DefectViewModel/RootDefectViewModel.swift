//
//  RootLessonViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 30/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum DefectStackActions {
    case set(viewModels: [Any], animated: Bool)
    case push(viewModel: Any, animated: Bool)
    case present(viewModel: Any, animated:Bool)
    case present1(viewController: UIViewController, animated:Bool)
    case pop(animated: Bool)
    case dismiss(animated: Bool)
    case presentui(text: String)
}

class RootDefectViewModel {
    
    lazy private(set) var defectViewModel: DefectViewModel = {
        return self.createDefectViewModel()
    }()
    
    lazy private(set) var defectMenuViewModel: DefectMenuViewModel = {
        return self.createDefectMenuViewModel()
    }()
    
    lazy private(set) var defectListViewModel: DefectListViewModel = {
        return self.createDefectListViewModel()
    }()
        
    lazy private(set) var addCommentViewModel: AddCommentViewModel = {
        return self.createAddCommentViewModel()
    }()
    
    lazy private(set) var addPlanViewModel: AddPlanViewModel = {
        return self.createAddPlanViewModel()
    }()
    
    lazy private(set) var defectDetailViewModel: DefectDetailViewModel = {
        return self.createDefectDetailViewModel()
    }()
    
    lazy private(set) var imageEditor: UIViewController = {
        
        let factory = AssemblyFactory()
        let assembly = factory.mediaPickerAssembly()
        
        let data = MediaPickerData(
            items: [],
            selectedItem: nil,
            maxItemsCount: 3,
            cropEnabled: true,
            hapticFeedbackEnabled: true,
            cropCanvasSize: CGSize(width: 1280, height: 960)
        )

        let viewController = assembly.module(
            data: data,
            configure: { [weak self] module in
                weak var module = module
                                
                module?.onFinish = { mediaPickerItems in
                    module?.dismissModule()
                    self?.defectDetailViewModel.photos.accept(mediaPickerItems.map { $0.image })
                }
                module?.onCancel = {
                    module?.dismissModule()
                }
        })
        viewController.hidesBottomBarWhenPushed = true
        
        return viewController
    }()
    
    lazy private(set) var defectStackActions: BehaviorSubject<DefectStackActions> = {
        return BehaviorSubject(value: .set(viewModels: [self.defectMenuViewModel], animated: false))
    }()
    
    private let disposeBag = DisposeBag()
    private let imageName = BehaviorRelay(value: "")
    private let tagPosition = BehaviorRelay<[String: CGPoint]>(value: [:])
    
    private let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
    
    func createDefectViewModel() -> DefectViewModel {
    
        let defectViewModel = DefectViewModel()
        
        return defectViewModel
    }
    
    func createAddPlanViewModel() -> AddPlanViewModel {
    
        let addPlanViewModel = AddPlanViewModel()
        
        return addPlanViewModel
    }
    
    func createAddCommentViewModel() -> AddCommentViewModel {
    
        let addCommentViewModel = AddCommentViewModel()
        
        addCommentViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveDefect()
            }
            }).disposed(by: disposeBag)
    
        return addCommentViewModel
    }
    
    func createRootAddDefectViewModel() -> RootAddDefectViewModel {
    
        let rootAddDefectViewModel = RootAddDefectViewModel(imageName.value, tagPosition.value)
        
        rootAddDefectViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveDefect()
            }
            }).disposed(by: disposeBag)
        
        return rootAddDefectViewModel
    }
    
    func createDefectListViewModel() -> DefectListViewModel {
    
        let defectListViewModel = DefectListViewModel()
        
        Observable.combineLatest(defectListViewModel.defectDetailModel, defectListViewModel.indexRow)
            .subscribe(onNext: { [weak self] model, index in
                
                if !model.isEmpty {
                    
                    if !model[0].defectComment.isEmpty {
                        self?.defectDetailViewModel.commentData.accept(model[0].defectComment)
                        self?.defectDetailViewModel.state.accept(.hasData)
                    } else {
                        self?.defectDetailViewModel.state.accept(.empty)
                    }
                    
                    if !model[0].defectImage.isEmpty {
                        self?.defectDetailViewModel.photoData.accept(model[0].defectImage)
                        self?.defectDetailViewModel.photoState.accept(.hasData)
                    } else {
                        self?.defectDetailViewModel.photoState.accept(.empty)
                    }
                    
                    self?.defectDetailViewModel.dueDate.accept("Create :  \(model[0].timeStamp)")
                    self?.defectDetailViewModel.createDate.accept("Due     :  \(model[0].dueDate)")
                    self?.defectDetailViewModel.title.accept(model[0].defectTitle)
                    self?.defectDetailViewModel.positionDefect.accept([model[0].defectPosition])
                    DefectDetails.shared.currentIndex = index
                }
            }).disposed(by: disposeBag)
        
        defectListViewModel.positionTag
            .subscribe(onNext: { [weak self] pos in
                self?.tagPosition.accept(pos)
            }).disposed(by: disposeBag)
        
        defectListViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .SelectDefect:
                self?.defectSelected()
            case .AddDefect:
                self?.addDefect()
            }
            }).disposed(by: disposeBag)
        
        
        return defectListViewModel
    }
    
    
    func createDefectDetailViewModel() -> DefectDetailViewModel {
    
        let defectDetailViewModel = DefectDetailViewModel()
                
        defectDetailViewModel.editComment
            .subscribe(onNext: { [weak self] comment in
                self?.addCommentViewModel.editComment.accept(comment)
            }).disposed(by: disposeBag)
        
        defectDetailViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .photoEdit:
                self?.presentImageEditor()
            case .doneDefect:
                return
            case .addComment:
                self?.addComment()
            }
            }).disposed(by: disposeBag)
        
        return defectDetailViewModel
    }
    
    func createDefectMenuViewModel() -> DefectMenuViewModel {
    
        let defectMenuViewModel = DefectMenuViewModel()
        
        defectMenuViewModel.planDetail
            .subscribe(onNext: { [weak self] image in
                self?.defectDetailViewModel.imageName.accept(image)
                self?.defectListViewModel.imageName.accept(image)
                self?.imageName.accept(image)
            }).disposed(by: disposeBag)
        
        defectMenuViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .SelectArea:
                self?.areaSelected()
            case .AddPlan:
                self?.addPlan()
            }
            }).disposed(by: disposeBag)
        
        return defectMenuViewModel
    }
    
    private func areaSelected() {
        self.defectStackActions.onNext(.push(viewModel: self.defectListViewModel, animated: true))
    }
    
    private func defectSelected() {
        self.defectStackActions.onNext(.push(viewModel: self.defectDetailViewModel, animated: true))
    }
    
    private func presentImageEditor() {
        self.defectStackActions.onNext(.present1(viewController: self.imageEditor, animated: true))
    }
    
    private func addDefect() {
        self.defectStackActions.onNext(.present(viewModel: self.createRootAddDefectViewModel(), animated: true))
    }
    
    private func addPlan() {
        self.defectStackActions.onNext(.present(viewModel: self.addPlanViewModel, animated: true))
    }
    
    private func addComment() {
        self.defectStackActions.onNext(.present(viewModel: self.addCommentViewModel, animated: true))
    }
    
    private func saveDefect() {
        self.defectStackActions.onNext(.dismiss(animated: true))
    }
}

