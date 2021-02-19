//
//  Global.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 26/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//
import Foundation
import UIKit
import CardParts
import RxCocoa

func viewController(forViewModel viewModel: Any) -> UIViewController? {
    
  switch viewModel {
  
  // MARK: - TabRootViewModel
  
  case let viewModel as TabRootViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabRootViewController") as? TabRootViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - MainMenuViewModel
  
  case let viewModel as MainMenuViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainMenuViewController") as? MainMenuViewController
    viewController?.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy)), tag: 0)
    let informationController = InformationController()
    let welcomeTextController = WelcomeTextController()
    let installationCard = InstallationCard()
    let todayTaskTable = TodayTaskTable()
    todayTaskTable.viewModel = viewModel
    installationCard.viewModel = viewModel
    informationController.viewModel = viewModel
    welcomeTextController.viewModel = viewModel
    viewController?.welcomeTextController = welcomeTextController
    viewController?.informationController = informationController
    viewController?.installationCard = installationCard
    viewController?.todayTaskTable = todayTaskTable
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - LessonViewModel
    
  case let viewModel as LessonViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LessonViewController") as? LessonViewController
    let lessonController = LessonTextController()
    lessonController.viewModel = viewModel
    viewController?.lessonTextController = lessonController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - ChooseLessonViewModel
    
  case let viewModel as ChooseLessonViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChooseLessonViewController") as? ChooseLessonViewController
    let chooseLessonController = ChooseLessonController()
    chooseLessonController.viewModel = viewModel
    viewController?.chooseLessonController = chooseLessonController
    viewController?.viewModel = viewModel
    viewController?.title = viewModel.topicHeader.value
    return viewController
    
  // MARK: - StartLessonViewModel
  
  case let viewModel as StartLessonViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "StartLessonViewController") as? StartLessonViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - AllQuizViewModel
  
  case let viewModel as AllQuizViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AllQuizViewController") as? AllQuizViewController
    let quizButtonCard = QuizButtonController()
    let quizListController = QuizListController()
    quizButtonCard.viewModel = viewModel
    quizListController.viewModel = viewModel
    viewController?.quizListController = quizListController
    viewController?.quizButtonController = quizButtonCard
    viewController?.viewModel = viewModel
    return viewController
  
  // MARK: - RootViewModel
  
  case let viewModel as RootViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootViewController") as? RootViewController
    viewController?.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy)), tag: 0)
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - KnowledgeMenuViewModel
  
  case let viewModel as KnowledgeMenuViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "KnowledgeMenuViewController") as? KnowledgeMenuViewController
    let knowledgeMenuController = KnowledgeMenuController()
    knowledgeMenuController.viewModel = viewModel
    viewController?.knowledgeMenuController = knowledgeMenuController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - QuizTemViewModel
  
  case let viewModel as QuizTemViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuizTemViewController") as? QuizTemViewController
    let quizSelectViewController = QuizSelectViewController()
    quizSelectViewController.viewModel = viewModel
    viewController?.quizSelectViewController = quizSelectViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - RootSelectDateViewModel
  
  case let viewModel as RootSelectDateViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootSelectDateViewContoller") as? RootSelectDateViewContoller
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - RootScheduleViewModel
  
  case let viewModel as RootScheduleViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootScheduleController") as? RootScheduleController
    
    viewController?.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy)), tag: 0)

    viewController?.viewModel = viewModel
    return viewController
  
  // MARK: - ScheduleViewModel
  
  case let viewModel as ScheduleViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScheduleController") as? ScheduleController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - AddTaskViewModel
  
  case let viewModel as AddTaskViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddTaskViewController") as? AddTaskViewController
    let addTaskCard = AddTaskController()
    viewController?.title = "Task Creator"
    addTaskCard.viewModel = viewModel
    viewController?.addTaskController = addTaskCard
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - AddDateViewModel
  
  case let viewModel as AddDateViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddDateViewController") as? AddDateViewController
    let addDateCard = AddDateController()
    viewController?.title = "Schedule Creator"
    addDateCard.viewModel = viewModel
    viewController?.addDateController = addDateCard
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - SelectTaskViewModel
  
  case let viewModel as SelectTaskViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SelectTaskViewController") as? SelectTaskViewController
    let selecTaskCard = SelectTaskController()
    selecTaskCard.viewModel = viewModel
    viewController?.selectTaskController = selecTaskCard
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - RootInstallViewModel
  
  case let viewModel as RootInstallViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootInstallViewController") as? RootInstallViewController
    viewController?.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy)), tag: 0)
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - InstallHistoryViewModel
  
  case let viewModel as InstallHistoryViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InstallHistoryViewController") as? InstallHistoryViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - InstallationViewModel
  
  case let viewModel as InstallationViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InstallationViewController") as? InstallationViewController
    let installText = InstallationText()
    let installTable = InstallTable()
    installText.viewModel = viewModel
    installTable.viewModel = viewModel
    viewController?.installationText = installText
    viewController?.installTable = installTable
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - InstallContentViewModel
  
  case let viewModel as InstallContentViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InstallContentViewController") as? InstallContentViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - RootDefectViewModel
  
  case let viewModel as RootDefectViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootDefectViewController") as? RootDefectViewController
    viewController?.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy)), tag: 0)
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - DefectViewModel
  
  case let viewModel as DefectViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DefectViewController") as? DefectViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - DefectListViewModel
  
  case let viewModel as DefectListViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DefectListViewController") as? DefectListViewController
    viewController?.title = "Defect Selection"
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - DefectDetailViewModel
  
  case let viewModel as DefectDetailViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DefectDetailViewController") as? DefectDetailViewController
    let commentTable = CommentTable()
    let defectDetailController = DefectDetailController()
    let photoTable = PhotoTable()
    defectDetailController.viewModel = viewModel
    commentTable.viewModel = viewModel
    photoTable.viewModel = viewModel
    viewController?.title = "Defect Detail"
    viewController?.defectDetailController = defectDetailController
    viewController?.commentTable = commentTable
    viewController?.photoTable = photoTable
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - AddCommentViewModel
  
  case let viewModel as AddCommentViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddCommentViewController") as? AddCommentViewController
    let addCommentController = AddCommentController()
    addCommentController.viewModel = viewModel
    viewController?.title = "Comment Creator"
    viewController?.addCommentController = addCommentController
    viewController?.viewModel = viewModel
    
    let navi =  UINavigationController.init(rootViewController: viewController!)
    
    return navi
    
  // MARK: - RootAddDefectViewModel
  
  case let viewModel as RootAddDefectViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RootAddDefectController") as? RootAddDefectController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - AddDefectViewModel
  
  case let viewModel as AddDefectViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddDefectViewController") as? AddDefectViewController
    let addDefectController = AddDefectController()
    addDefectController.viewModel = viewModel
    viewController?.title = "Defect Creator"
    viewController?.addDefectController = addDefectController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - SelectPositionViewModel
  
  case let viewModel as SelectPositionViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SelectPositionViewController") as? SelectPositionViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - DefectMenuViewModel
  
  case let viewModel as DefectMenuViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DefectMenuViewController") as? DefectMenuViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - DashBoardViewModel
  
  case let viewModel as DashBoardViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DashBoardViewController") as? DashBoardViewController
    let contentCard = ContentCardController()
    contentCard.viewModel = viewModel
    viewController?.contentCardController = contentCard
    viewController?.viewModel = viewModel
    
    return viewController
    
  // MARK: - SessionViewModel
  
  case let viewModel as SessionViewModel:
      let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SessionViewController") as? SessionViewController
      viewController?.viewModel = viewModel
      return viewController
    
  case let viewModel as ChooseTopicViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChooseTopicViewController") as? ChooseTopicViewController
    viewController?.viewModel = viewModel
    return viewController
    
  // MARK: - UserViewModel
  
  case let viewModel as UserViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserViewController") as? UserViewController
    let userCard = UserViewCardController()
    userCard.viewModel = viewModel
    viewController?.userController = userCard
    return viewController
      
  // MARK: - QuizResultViewModel
  
  case let viewModel as QuizResultViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuizResultController") as? QuizResultController
    let resultCard = ResultController()
    let endCard = EndController()
      
    endCard.viewModel = viewModel
    resultCard.viewModel = viewModel
    viewController?.endController = endCard
    viewController?.resultController = resultCard
    
    return viewController

  // MARK: - QuizViewModel
  
  case let viewModel as QuizViewModel:
    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController
    let quizCard = QuizController()
    
    quizCard.viewModel = viewModel
    viewController?.quizController = quizCard
    
    return viewController
  
  default:
    return nil
  }
}


func isStringContainsOnlyNumbers(string: String) -> Bool {
     return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
 }

func setGradient(stack: CardPartStackView, colours: [UIColor], gradient: CAGradientLayer, borderView: UIView, radius: Int) {
    
    gradient.colors =  colours.map { $0.cgColor }
    gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
    gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
    
    stack.backgroundView.layer.shadowColor = UIColor.black.cgColor
    stack.backgroundView.layer.shadowOffset = CGSize(width: 3, height: 3)
    stack.backgroundView.layer.shadowOpacity = 0.5
    stack.backgroundView.layer.shadowRadius = 4.0
    
    borderView.layer.cornerRadius = CGFloat(radius)
    borderView.layer.masksToBounds = true
    borderView.layer.insertSublayer(gradient, at: 0)
    
    stack.backgroundView.addSubview(borderView)
}
