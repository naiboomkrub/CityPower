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
    
    lazy private(set) var siteDetailViewModel: SiteDetailViewModel = {
        return self.createSiteDetailViewModel()
    }()
    
    lazy private(set) var siteListViewModel: SiteListViewModel = {
        DefectDetails.shared.loadSite()
        return self.createSiteListViewModel()
    }()
    
    lazy private(set) var defectMenuViewModel: DefectMenuViewModel = {
        DefectDetails.shared.loadDefect()
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
        return BehaviorSubject(value: .set(viewModels: [self.siteListViewModel], animated: false))
    }()
    
    private let disposeBag = DisposeBag()
    private let imageName = BehaviorRelay(value: "")
    private let tagPosition = BehaviorRelay(value: [ImagePosition]())
    
    private let formatterDay: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "dd/MM/yyyy"
         return formatter
     }()
    
    func createDefectViewModel() -> DefectViewModel {
    
        let defectViewModel = DefectViewModel()
        
        return defectViewModel
    }
    
    func createSiteListViewModel() -> SiteListViewModel {
    
        let siteListViewModel = SiteListViewModel()
        
        siteListViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .SelectSite:
                self?.siteSelected()
            }
            }).disposed(by: disposeBag)
        
        return siteListViewModel
    }
    
    func createSiteDetailViewModel() -> SiteDetailViewModel {
    
        let siteDetailViewModel = SiteDetailViewModel()
        
        siteDetailViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .selectArea:
                return
            case .selectDefect:
                self?.startDefectMenu()
            case .selectUnit:
                return
            }
            }).disposed(by: disposeBag)
        
        return siteDetailViewModel
    }
    
    func createAddPlanViewModel() -> AddPlanViewModel {
    
        let addPlanViewModel = AddPlanViewModel()
        
        addPlanViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Save:
                self?.saveDefect()
            }
            }).disposed(by: disposeBag)
        
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
        
        defectListViewModel.defectDetailModel.subscribe(onNext: { [weak self] model in
                
                if !model.isEmpty {
                    
                    self?.defectDetailViewModel.photoData.accept(model[0].defectImage)
                    self?.defectDetailViewModel.commentData.accept(model[0].defectComment)
                    
                    if !model[0].defectComment.isEmpty {
                        self?.defectDetailViewModel.state.accept(.hasData)
                    } else {
                        self?.defectDetailViewModel.state.accept(.empty)
                    }
                    
                    if !model[0].defectImage.isEmpty {
                        self?.defectDetailViewModel.photoState.accept(.hasData)
                    } else {
                        self?.defectDetailViewModel.photoState.accept(.empty)
                    }
                    
                    self?.defectDetailViewModel.status.accept(model[0].status)
                    self?.defectDetailViewModel.dueDate.accept("Create :  \(model[0].timeStamp)")
                    self?.defectDetailViewModel.createDate.accept("Due     :  \(model[0].dueDate)")
                    self?.defectDetailViewModel.title.accept(model[0].defectTitle)
                    self?.defectDetailViewModel.positionDefect.accept([model[0].position])
                    self?.defectDetailViewModel.photos.accept([])
                    DefectDetails.shared.currentIndex = Int(model[0].defectNumber)
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
                self?.doneDefect()
            case .addComment:
                self?.addComment()
            }
            }).disposed(by: disposeBag)
        
        return defectDetailViewModel
    }
    
    func createDefectMenuViewModel() -> DefectMenuViewModel {
    
        let defectMenuViewModel = DefectMenuViewModel()
        
        Observable.combineLatest( defectMenuViewModel.planDetail, defectMenuViewModel.indexRow)
            .subscribe(onNext: { [weak self] image, index in
                self?.defectDetailViewModel.imageName.accept(image)
                self?.defectListViewModel.imageName.accept(image)
                self?.imageName.accept(image)
                DefectDetails.shared.currentGroup = index
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
    
    private func startDefectMenu() {
        self.defectStackActions.onNext(.push(viewModel: self.defectMenuViewModel, animated: true))
    }
    
    private func siteSelected() {
        self.defectStackActions.onNext(.push(viewModel: self.siteDetailViewModel, animated: true))
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
    
    private func doneDefect() {
        self.defectStackActions.onNext(.pop(animated: true))
    }
    
    private func addComment() {
        self.defectStackActions.onNext(.present(viewModel: self.addCommentViewModel, animated: true))
    }
    
    private func saveDefect() {
        self.defectStackActions.onNext(.dismiss(animated: true))
    }
}

