//
//  ScheduleController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 1/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import FSCalendar
import RxDataSources

class ScheduleController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, CustomSegmentedControlDelegate, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var calendarHeight: NSLayoutConstraint!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var taskSchedule: UIView!
    @IBOutlet weak var taskManage: UIView!
    @IBOutlet weak var switchView: UIView!
    @IBOutlet weak var taskTable: UITableView!
    @IBOutlet weak var taskHeader: UILabel!
    @IBOutlet weak var addTaskWindow: UIBarButtonItem!
    @IBOutlet weak var taskEdit: UIButton!
    @IBOutlet weak var scheduleTable: UITableView!
    @IBOutlet weak var scheduleLabel: UILabel!
    @IBOutlet weak var scheduleEdit: UIButton!
    
    var viewModel: ScheduleViewModel!
    var calendar: FSCalendar!
    
    typealias TaskAllSection = AnimatableSectionModel<String, EventTask>
    typealias ScheduleAllSection = AnimatableSectionModel<String, Task>
    
    private let disposeBag = DisposeBag()
    
    func change(to index: Int) {
        
        if index == 0 {
            taskSchedule.isHidden = true
            taskManage.isHidden = false
            self.viewModel.reloadData()
        }
        else {
            taskSchedule.isHidden = false
            taskManage.isHidden = true
        }
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        }
       
        viewModel.date.accept(formatter.string(from: date))
        viewModel.changeDate()
        
        if viewModel.tempData.count == 0 {
            scheduleTable.setEmptyMessage("Please Insert Schedule")
        } else {
            scheduleTable.restore()
        }
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateString = self.formatter.string(from: date)
        
        for task in Schedule.shared.savedTask {
            if task.date.contains(dateString) {
                return 1
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let currentCell = tableView.cellForRow(at: indexPath) as? ScheduleTableViewCell else { return }
        
        UIView.animate(withDuration: 0.15, animations: {
            currentCell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }, completion: { _ in
                    UIView.animate(withDuration: 0.15) {
                        currentCell.transform = CGAffineTransform(scaleX: 1, y: 1)}
        })
        
        if !currentCell.click {
            currentCell.scheduleView.backgroundColor = .correct
            currentCell.click = true
        } else {
            currentCell.scheduleView.backgroundColor = .wrong
            currentCell.click = false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == taskTable {
            return 150
        } else {
            return 75
        }
    }
        
    let gregorian = Calendar(identifier: .gregorian)
    let formatter: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy-MM-dd"
         return formatter
     }()
    
    lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    func setUpTable() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<TaskAllSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath)
        
        viewModel.dataSource
            .map { [TaskAllSection(model: "", items: $0)] }
            .bind(to: taskTable.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        taskTable.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            self.viewModel.removeData(index: indexPath)
            self.calendar.reloadData()
            
            if EventTasks.shared.savedTask.count == 0 {
                self.taskTable.setEmptyMessage("Please Insert Task")
            }
            
            if self.viewModel.tempData.count == 0 {
                self.scheduleTable.setEmptyMessage("Please Insert Schedule")
            }
            
        }).disposed(by: disposeBag)
        
        taskTable.rx.itemMoved
            .subscribe(onNext: { [unowned self] source, destination in
                guard source != destination else { return }
                let item = self.viewModel.dataSource.value[source.row]
                self.viewModel.swapData(index: source, insertIndex: destination, element: item)
            })
            .disposed(by: disposeBag)
        
        taskTable.rx.modelSelected(EventTask.self)
            .subscribe(onNext: { [unowned self] task in
                self.viewModel.editTask(taskClick: [task])
            })
            .disposed(by: disposeBag)
    
    }
    
    func setUpSchedule() {
        
        let dataSource = RxTableViewSectionedAnimatedDataSource<ScheduleAllSection>(
            animationConfiguration: AnimationConfiguration(insertAnimation: .right,
                                                           reloadAnimation: .fade,
                                                           deleteAnimation: .left),
            configureCell: configureCell2,
            canEditRowAtIndexPath: canEditRowAtIndexPath2,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath2)
        
        viewModel.scheduleSource
            .map { [ScheduleAllSection(model: "", items: $0)] }
            .bind(to: scheduleTable.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        scheduleTable.rx.itemDeleted.subscribe ( onNext: { [unowned self] indexPath in
            self.viewModel.removeSchedule(index: indexPath)
    
            if self.viewModel.tempData.count == 0 {
                self.scheduleTable.setEmptyMessage("Please Insert Schedule")
            }
        }).disposed(by: disposeBag)
        
        scheduleTable.rx.itemMoved
            .subscribe(onNext: { [unowned self] source, destination in
                guard source != destination else { return }
                let item = self.viewModel.scheduleSource.value[source.row]
                self.viewModel.swapSchedule(index: source, insertIndex: destination, element: item)
            })
            .disposed(by: disposeBag)
        
        scheduleTable.rx.modelSelected(Task.self)
            .subscribe(onNext: { [unowned self] task in
                self.viewModel.taskDone(taskClick: task)
            })
            .disposed(by: disposeBag)
    }
        
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.scheduleTable.contentOffset.y <= -self.scheduleTable.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.taskSchedule)
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            default:
                return velocity.y < 0
            }
        }
        return shouldBegin
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeight.constant = bounds.height
        calendar.frame = CGRect(origin: calendar.frame.origin, size: bounds.size)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskTable.separatorStyle = .none
        scheduleTable.separatorStyle = .none
        taskTable.rx.setDelegate(self).disposed(by: disposeBag)
        scheduleTable.rx.setDelegate(self).disposed(by: disposeBag)
        
        scheduleLabel.text = "Schedule Table"
        scheduleLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
        taskSchedule.isHidden = true
        taskManage.isHidden = false
        taskHeader.text = "Task Progress / Manday"
        taskHeader.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(25))!
        
        let calendar = FSCalendar(frame: CGRect(x:0, y: 20, width: self.view.bounds.size.width, height: self.calendarView.bounds.size.height))
        
        let segmented = CustomSegmentedControl(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50), buttonTitle: ["Task","Schedule"])
        segmented.backgroundColor = .clear
        segmented.delegate = self
        
        calendar.dataSource = self
        calendar.delegate = self
        calendar.allowsMultipleSelection = false
        calendar.appearance.headerTitleColor = UIColor.white
        calendar.appearance.weekdayTextColor = UIColor.blueCity
        calendar.calendarHeaderView.backgroundColor = UIColor.blueCity
        calendar.weekdayHeight = 40
        calendar.appearance.headerTitleFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(16))!
        calendar.appearance.weekdayFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(16))!
        
        calendarView.addSubview(calendar)
        switchView.addSubview(segmented)
        
        addTaskWindow.rx.tap.bind(onNext: { [unowned self] in
            if taskSchedule.isHidden {
                self.viewModel.addTask() }
            else {
                self.viewModel.addDate()
            }
        }).disposed(by: disposeBag)
        
        self.calendar = calendar
        self.taskSchedule.addGestureRecognizer(self.scopeGesture)
        self.scheduleTable.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.calendar.select(Date())
        
        viewModel.date.accept(formatter.string(from: Date()))
        
        taskEdit.setTitle("Edit", for: .normal)
        taskEdit.setTitleColor(.blueCity, for: .normal)
        taskEdit.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        scheduleEdit.setTitle("Edit", for: .normal)
        scheduleEdit.setTitleColor(.blueCity, for: .normal)
        scheduleEdit.titleLabel?.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        
        taskTable.dataSource = nil
        scheduleTable.dataSource = nil
        setUpTable()
        setUpSchedule()
        
        scheduleEdit.rx.tap
            .map { [unowned self] in self.scheduleTable.isEditing }
            .bind(onNext: { [unowned self] result in
                self.scheduleTable.setEditing(!result, animated: true)
                if !result { self.scheduleEdit.setTitle("Done", for: .normal) }
                else { self.scheduleEdit.setTitle("Edit", for: .normal) }
            })
            .disposed(by: disposeBag)
        
        taskEdit.rx.tap
            .map { [unowned self] in self.taskTable.isEditing }
            .bind(onNext: { [unowned self] result in
                self.taskTable.setEditing(!result, animated: true)
                if !result { self.taskEdit.setTitle("Done", for: .normal) }
                else { self.taskEdit.setTitle("Edit", for: .normal) }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if EventTasks.shared.savedTask.count == 0 {
            taskTable.setEmptyMessage("Please Insert Task")
        } else {
            taskTable.restore()
            viewModel.reloadData()
            viewModel.changeDate()
        }
        
        if viewModel.tempData.count == 0 {
            scheduleTable.setEmptyMessage("Please Insert Schedule")
        } else {
            scheduleTable.restore()
        }
    }
}


class TaskAllTableViewCell: UITableViewCell {

    @IBOutlet weak var taskCell: UIView!
    @IBOutlet weak var taskDes: UILabel!
    @IBOutlet weak var Manday: UILabel!
    @IBOutlet weak var mandayBar: UIProgressView!
    
    var mandayUsed = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.taskCell.layer.borderWidth = 1
        
        self.taskDes.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
        self.Manday.font = UIFont(name: "Baskerville-Bold", size: CGFloat(16))!
        
        self.mandayBar.progress = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setData (_ data: EventTask) {
        self.taskDes.text = data.taskTitle
        self.Manday.text = data.manDay
        
        var mandayPresent = 0
        
        for task in Schedule.shared.savedTask {
            if task.eventTask == data.taskTitle {
                mandayPresent += Int(task.labour)!
            }
        }
        
        if isStringContainsOnlyNumbers(string: data.manDay) && self.mandayUsed != mandayPresent {
            self.mandayBar.progress = (Float(mandayPresent) / Float(data.manDay)!)
            self.mandayUsed = mandayPresent
        }
    }
}


extension ScheduleController {
    
    
    private var configureCell: RxTableViewSectionedAnimatedDataSource<TaskAllSection>.ConfigureCell {
        return {  _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskAllCell", for: indexPath) as? TaskAllTableViewCell else { return UITableViewCell() }

            cell.setData(item)
            
            return cell
        }
    }
    
    private var configureCell2: RxTableViewSectionedAnimatedDataSource<ScheduleAllSection>.ConfigureCell {
        return { _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleTableViewCell", for: indexPath) as? ScheduleTableViewCell else { return UITableViewCell() }

                 cell.setData(item)
            
            return cell
        }
    }
    
    private var canEditRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<TaskAllSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.taskTable.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    private var canMoveRowAtIndexPath: RxTableViewSectionedAnimatedDataSource<TaskAllSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return true
        }
    }
    
    private var canEditRowAtIndexPath2: RxTableViewSectionedAnimatedDataSource<ScheduleAllSection>.CanEditRowAtIndexPath {
        return { [unowned self] _, _ in
            if self.scheduleTable.isEditing {
                return true
            } else {
                return false
            }
        }
    }
    
    private var canMoveRowAtIndexPath2: RxTableViewSectionedAnimatedDataSource<ScheduleAllSection>.CanMoveRowAtIndexPath {
        return { _, _ in
            return true
        }
    }
}


class ScheduleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var scheduleView: UIView!
    @IBOutlet weak var scheduleTitle: UILabel!
    @IBOutlet weak var scheduleMan: UILabel!
    
    var click : Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.scheduleView.layer.cornerRadius = 10.0
        
        self.scheduleTitle.font = UIFont(name: "SukhumvitSet-Text", size: CGFloat(16))!
        self.scheduleMan.font = UIFont(name: "Baskerville-Bold", size: CGFloat(16))!
        
    }

    func setData (_ data: Task) {
        self.scheduleTitle.text = data.eventTask
        self.scheduleMan.text = data.labour
        self.scheduleView.backgroundColor = data.done ? .correct : .wrong
        self.click = data.done
    }
}

extension UITableView {

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
        messageLabel.alpha = 0.5
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel
    }

    func restore() {
        self.backgroundView = nil
    }
}

