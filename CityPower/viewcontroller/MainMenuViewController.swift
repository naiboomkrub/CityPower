//
//  MainMenuViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 27/11/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift


class MainMenuViewController: CardsViewController {
    
    var viewModel: MainMenuViewModel!
    var todayTaskTable: TodayTaskTable!
    var informationController: InformationController!
    var welcomeTextController: WelcomeTextController!
    var installationCard: InstallationCard!
        
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let cards: [CardController] = [welcomeTextController, informationController, TopicTaskController(), todayTaskTable, InstallationRecord(), installationCard]
 
        loadCards(cards: cards)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.changeDate()
    }
}

class WelcomeTextController: CardPartsViewController, GradientCardTrait {
    
    var viewModel: MainMenuViewModel!
    
    func gradientColors() -> [UIColor] {
        return [.sanitary, .sanitary2]
    }
    
    let welcomeView = CardPartTextView(type: .header)
    let userView = CardPartTextView(type: .normal)
    let welcomeStack = CardPartStackView()
    let logoImage = CardPartImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoImage.imageName = "Asset 20"
        logoImage.contentMode = .scaleAspectFit
        logoImage.addConstraint(NSLayoutConstraint(item: logoImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 150))
        welcomeView.text = "City Power"
        welcomeStack.axis = .vertical
        welcomeStack.spacing = 0
        welcomeStack.distribution = .equalSpacing
        welcomeStack.isLayoutMarginsRelativeArrangement = true
        welcomeStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        welcomeStack.pinBackground(welcomeStack.backgroundView, to: welcomeStack)

        userView.margins = UIEdgeInsets(top: -40, left: 25, bottom: 20, right: 20)
        userView.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(28))!
        
        [logoImage, welcomeView].forEach { label in
            welcomeStack.addArrangedSubview(label)}
        
        viewModel.username.asObservable().bind(to: userView.rx.text).disposed(by: bag)
        
        setupCardParts([welcomeStack, userView])
    }
}


class InformationController: CardPartsViewController, TransparentCardTrait {
    
    var viewModel: MainMenuViewModel!
    
    let inforView = CardPartTextView(type: .normal)
    let progressInfo = CardPartTextView(type: .normal)
    let inforStack = CardPartStackView()
    let circleLayer = CAShapeLayer()
    let progressLayer = CAShapeLayer()
    let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: 334 * 1 / 4, y: 130 / 2), radius: 30, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)
        
        circleLayer.path = circularPath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineWidth = 10.0
        circleLayer.strokeColor = UIColor.black.cgColor
        
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = 10.0
        progressLayer.strokeColor = UIColor.lightBlueCity.cgColor
        
        gradientLayer.colors =  [UIColor.start1.cgColor, UIColor.start2.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        inforView.text = "Today's Tasks"
        inforView.textColor = .white
        progressInfo.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        progressInfo.textColor = .white
        
        inforStack.axis = .vertical
        inforStack.spacing = 20
        inforStack.distribution = .equalSpacing
        inforStack.margins = UIEdgeInsets(top: 30, left: 20, bottom: 10, right: 20)
        inforStack.isLayoutMarginsRelativeArrangement = true
        inforStack.layoutMargins = UIEdgeInsets(top: 20, left: 394 * 2 / 5, bottom: 20, right: 10)
        inforStack.backgroundView.layer.shadowColor = UIColor.black.cgColor
        inforStack.backgroundView.layer.shadowOffset = CGSize(width: 3, height: 3)
        inforStack.backgroundView.layer.shadowOpacity = 0.5
        inforStack.backgroundView.layer.shadowRadius = 4.0
        inforStack.backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        inforStack.pinBackground(inforStack.backgroundView, to: inforStack)
        
        inforStack.backgroundView.layer.addSublayer(circleLayer)
        inforStack.backgroundView.layer.addSublayer(progressLayer)
        
        [inforView, progressInfo].forEach { label in
            inforStack.addArrangedSubview(label)}
        
        viewModel.progressData.asObservable().bind(onNext:{ [weak self] value in
            self?.progressLayer.strokeEnd = CGFloat(value)
        }).disposed(by: bag)
        
        viewModel.taskNumber.asObservable().bind(to: progressInfo.rx.text).disposed(by: bag)
        
        setupCardParts([inforStack])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.gradientLayer.frame = self.inforStack.backgroundView.bounds
    }
}


class TopicTaskController: CardPartsViewController, TransparentCardTrait {
    
    let topicTask = CardPartTextView(type: .header)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topicTask.text = "Task Table"
        topicTask.textColor = .blueCity
        topicTask.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(28))!
        topicTask.margins = UIEdgeInsets(top: 20, left: 30, bottom: 10, right: 20)
        setupCardParts([topicTask])
    }
}


class TodayTaskTable: CardPartsViewController, CardPartTableViewDelegate, CustomMarginCardTrait {
    
    func customMargin() -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  //      guard let currentCell = tableView.cellForRow(at: indexPath) as? CardPartTableViewCell else { return }
  }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    var viewModel: MainMenuViewModel!
    
    let todayTaskTable = CardPartTableView()
    let textEmpty = CardPartTextView(type: .normal)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textEmpty.text = "No Task"
        textEmpty.textAlignment = .center
        textEmpty.margins = UIEdgeInsets(top: 40, left: 0, bottom: 40, right: 0)
        textEmpty.textColor = .general2
        
        todayTaskTable.tableView.allowsMultipleSelection = false
        todayTaskTable.tableView.dataSource = nil
        todayTaskTable.delegate = self
        todayTaskTable.margins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        todayTaskTable.tableView.rx.modelSelected(Task.self)
            .subscribe(onNext: { [unowned self] task in
                self.viewModel.taskDone(taskClick: task)
            })
            .disposed(by: bag)
        
        viewModel.listData.asObservable().bind(to: todayTaskTable.tableView.rx.items) { tableView, index, data in
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: IndexPath(item: index, section: 0)) as?  CardPartTableViewCell else { return UITableViewCell() }
            
            cell.margins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            cell.leftTitleLabel.text = data.eventTask
            cell.rightTitleLabel.text = data.labour
            cell.backgroundColor = data.done ? .lightBlueCity : .clear
            
            return cell
        }.disposed(by: bag)
        
        viewModel.state.asObservable().bind(to: self.rx.state).disposed(by: bag)
        
        setupCardParts([todayTaskTable], forState: .hasData)
        setupCardParts([textEmpty], forState: .empty)
    }
}

class InstallationRecord: CardPartsViewController, TransparentCardTrait {
    
    let installRec = CardPartTextView(type: .header)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installRec.text = "Installation Record"
        installRec.textColor = .blueCity
        installRec.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(28))!
        installRec.margins = UIEdgeInsets(top: 20, left: 30, bottom: 10, right: 20)
        setupCardParts([installRec])
    }
}

class InstallationCard: CardPartsViewController, CustomMarginCardTrait {
    
    var viewModel: MainMenuViewModel!
    
    func customMargin() -> CGFloat {
        return 15
    }
    
    let totalCompleted = CardPartTextView(type: .normal)
    let totalOngoing = CardPartTextView(type: .normal)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        totalOngoing.textColor = .black
        totalCompleted.textColor = .black
        totalCompleted.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
        totalCompleted.margins = UIEdgeInsets(top: 10, left: 30, bottom: 20, right: 20)
        totalOngoing.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
        totalOngoing.margins = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 20)
     
        viewModel.completed.asObservable().bind(to: totalCompleted.rx.text).disposed(by: bag)
        viewModel.incompleted.asObservable().bind(to: totalOngoing.rx.text).disposed(by: bag)
        
        setupCardParts([totalOngoing, totalCompleted])
    }
}
