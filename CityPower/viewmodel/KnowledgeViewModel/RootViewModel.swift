//
//  RootViewModel.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 26/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxSwift

    
enum NavigationStackAction {
    case set(viewModels: [Any], animated: Bool)
    case push(viewModel: Any, animated: Bool)
    case present(viewModel: Any, animated:Bool)
    case pop(animated: Bool)
    case dismiss(animated: Bool)
    case presentui(text: String)
}

class RootViewModel {
    
    lazy private(set) var dashBoardViewModel: DashBoardViewModel = {
        return self.createDashBoardViewModel()
    }()
    
    lazy private(set) var allQuizViewModel: AllQuizViewModel = {
        return self.createAllQuizViewModel()
    }()
    
    lazy private(set) var lessonViewModel: LessonViewModel = {
        return self.createLessonViewModel()
    }()
    
    lazy private(set) var chooseLessonViewModel: ChooseLessonViewModel = {
        return self.createChooseLessonViewModel()
    }()
    
    lazy private(set) var quizTemViewModel: QuizTemViewModel = {
        return self.createQuizTemViewModel()
    }()
    
    lazy private(set) var knowledgeMenuViewModel: KnowledgeMenuViewModel = {
        return self.createKnowledgeMenuViewModel()
    }()
    
    lazy private(set) var navigationStackActions: BehaviorSubject<NavigationStackAction> = {
        return BehaviorSubject(value: .set(viewModels: [self.knowledgeMenuViewModel], animated: false))
    }()
    
    var colorGrad: [UIColor]?
    
    private let disposeBag = DisposeBag()
    
    func createAllQuizViewModel() -> AllQuizViewModel {
      
        let allQuizViewModel = AllQuizViewModel()
        allQuizViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .KorWor:
                self?.korworView()
            case .Quiz:
                self?.normalQuiz()
            }
            }).disposed(by: disposeBag)
        
        return allQuizViewModel
    }
    
    func createQuizTemViewModel() -> QuizTemViewModel {
      
        let quizTemViewModel = QuizTemViewModel(quizSelected: allQuizViewModel.quizSelected.value)
        quizTemViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .StartNormal:
                self?.launchNormal()
            }
            }).disposed(by: disposeBag)
        
        return quizTemViewModel
    }
    
    func createChooseLessonViewModel() -> ChooseLessonViewModel {
    
        let chooseLessonViewModel = ChooseLessonViewModel()
        
        lessonViewModel.contentHeader.asObservable().bind(to: chooseLessonViewModel.topicHeader).disposed(by: disposeBag)
        
        chooseLessonViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .StartLesson:
                self?.startLesson()
            }
            }).disposed(by: disposeBag)

        return chooseLessonViewModel
    }
    
    func createStartLessonViewModel() -> StartLessonViewModel {
    
        let startLessonViewModel = StartLessonViewModel()
        
        return startLessonViewModel
    }
    
    func createLessonViewModel() -> LessonViewModel {
    
        let lessonViewModel = LessonViewModel()
        
        lessonViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .ChoseTopic:
                self?.choseLesson()
            }
            }).disposed(by: disposeBag)
        
        return lessonViewModel
    }
    
    
    func createDashBoardViewModel() -> DashBoardViewModel  {
    
        let dashBoardViewModel = DashBoardViewModel()
        dashBoardViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Start:
                self?.launchQuiz()
            case .Select:
                self?.selectTopic()
            case .User:
                self?.userView()
            case .Exit:
                self?.exitKorWor()
            }
            }).disposed(by: disposeBag)
    
        return dashBoardViewModel
    }
    
    func createSessionViewModel(textOnly: Bool) -> SessionViewModel {
      
        let sessionViewModel = SessionViewModel(textOnly: textOnly)
        sessionViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Finish:
                self?.finishQuiz()
            }
            }).disposed(by: disposeBag)
        
        if let color = self.colorGrad {
            sessionViewModel.colorGrad.accept(color)
        }

      return sessionViewModel
    }
    
    func createResultViewModel() -> QuizResultViewModel {
      
        let quizResultViewModel = QuizResultViewModel()
        quizResultViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Quit:
                self?.exitQuiz()
            }
            }).disposed(by: disposeBag)
        
      return quizResultViewModel
    }
    
    func createUserViewModel() -> UserViewModel {
      
        let userViewModel = UserViewModel()
        
      return userViewModel
    }
    
    func createKnowledgeMenuViewModel() -> KnowledgeMenuViewModel {
      
        let knowledgeMenuViewModel = KnowledgeMenuViewModel()
        knowledgeMenuViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .StartQuiz:
                self?.startQuizMenu()
            case .StartLesson:
                self?.startLessonMenu()
            }
            }).disposed(by: disposeBag)
        
      return knowledgeMenuViewModel
    }
    
    func createSelectViewModel() -> ChooseTopicViewModel {
        
        let chooseTopicViewModel = ChooseTopicViewModel()
        chooseTopicViewModel.title
            .subscribe(onNext: { [weak self] topic in
                self?.dashBoardViewModel.selectTopic.accept(topic)
            }).disposed(by: disposeBag)
        
        chooseTopicViewModel.topic
            .subscribe(onNext: { [weak self] topic in
                switch topic {
                case "General":
                    self?.colorGrad = [.general, .general2]
                case "Sanitary":
                    self?.colorGrad = [.sanitary, .sanitary2]
                case "Mechanic":
                    self?.colorGrad = [.mechincal, .mechincal2]
                case "Electrical":
                    self?.colorGrad = [.electrical, .electrical2]
                default:
                    self?.colorGrad = [.white, .white]
                }
                if let color = self?.colorGrad {
                    self?.dashBoardViewModel.colorGrad.accept(color)}
            }).disposed(by: disposeBag)
        
        chooseTopicViewModel.events
            .subscribe(onNext: { [weak self] event in
            switch event {
            case .Selected:
                self?.selectedTopic()
            }
            }).disposed(by: disposeBag)
        
        return chooseTopicViewModel
    }
    
    private func launchQuiz() {
        
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        
        let selectCategory = dashBoardViewModel.selectTopic.value
        let choiceNumber = dashBoardViewModel.choiceNum.value
        
        if selectCategory.contains("เลือกวิชา") || choiceNumber <= 0 || choiceNumber > 100 {
            
            self.navigationStackActions.onNext(.presentui(text: "ข้อมูลไม่ถูกต้อง"))
            
        } else {
        
            let mQuiz: [Quiz] = DataManager().getQuizzes(selectCategory, choiceNumber)
            GameSession.shared.resetSession()
            GameSession.shared.setQuizzes(newQuiz: mQuiz)
            self.navigationStackActions.onNext(.push(viewModel:  self.createSessionViewModel(textOnly: false), animated: true))
            
        }
    }
    
    private func launchNormal() {
        
        let selectCategory = quizTemViewModel.quizSelected.value
        
        let mQuiz: [Quiz] = DataManager().getQuizzes(selectCategory)
        GameSession.shared.resetSession()
        GameSession.shared.setQuizzes(newQuiz: mQuiz)
        self.navigationStackActions.onNext(.push(viewModel:  self.createSessionViewModel(textOnly: true), animated: true))
            
    }
    
    private func korworView() {
        self.navigationStackActions.onNext(.push(viewModel: self.dashBoardViewModel, animated: true))
    }
    
    private func exitQuiz() {
        self.navigationStackActions.onNext(.set(viewModels: [self.knowledgeMenuViewModel, self.allQuizViewModel, self.dashBoardViewModel], animated: true))
    }
    
    private func startQuizMenu() {
        self.navigationStackActions.onNext(.push(viewModel: self.allQuizViewModel, animated: true))
    }
    
    private func startLessonMenu() {
        self.navigationStackActions.onNext(.push(viewModel: self.lessonViewModel, animated: true))
    }
    
    private func userView() {
        self.navigationStackActions.onNext(.push(viewModel: self.createUserViewModel(), animated: true))
    }
    
    private func normalQuiz() {
        self.navigationStackActions.onNext(.push(viewModel: self.quizTemViewModel, animated: true))
    }
    
    private func finishQuiz() {
        self.navigationStackActions.onNext(.set(viewModels: [self.createResultViewModel()], animated: true))
    }
    
    private func selectTopic() {
        self.navigationStackActions.onNext(.present(viewModel: self.createSelectViewModel(), animated: true))
    }
    
    private func selectedTopic() {
        self.navigationStackActions.onNext(.dismiss(animated: true))
    }
    
    private func exitKorWor() {
        self.navigationStackActions.onNext(.pop(animated: true))
    }
    
    private func choseLesson() {
        self.navigationStackActions.onNext(.push(viewModel: self.chooseLessonViewModel, animated: true))
    }
    
    private func startLesson() {
        self.navigationStackActions.onNext(.push(viewModel: self.createStartLessonViewModel(), animated: true))
    }
}

