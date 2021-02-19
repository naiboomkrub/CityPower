//
//  chooseTopicViewModel.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 28/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import RxCocoa
import RxSwift
import RxDataSources


struct MySect {
    var header: String
}

struct MyStruct {
    var title: String
    var category : String
}

typealias MySection = SectionModel<TableViewSection,TableViewItem>

enum TableViewSection {
    case main(info: MySect)
}

enum TableViewItem {
    case subject(info: MyStruct)
}


class ChooseTopicViewModel {
    
    let title = BehaviorRelay(value: "")
    let topic = BehaviorRelay(value: "")
    let sections = PublishSubject<[MySection]>()

    var tempData: [TableViewItem] = []
    var allSection: [MySection] = []
    var finalTopic: [String] = []
    
    enum Event {
       case Selected
     }

    let events = PublishSubject<Event>()
        
    init() {  title.accept("เลือกวิชา")    }
    
    func selectTopic() {
          
        events.onNext(.Selected)
      }
    
    func exitTopic() {
        
        title.accept("เลือกวิชา")
        events.onNext(.Selected)
    }
    
    func reloadData(topic: String) {
        
        allSection.removeAll()
        
        if !finalTopic.contains(topic) {
            
            let allStruct: [MyStruct] = [MyStruct(title: "Computer Programming", category: "General"),
                                         MyStruct(title: "Engineering Drawing", category: "General"),
                                         MyStruct(title: "Engineering Material", category: "General"),
                                         MyStruct(title: "Engineering Mechanic", category: "General"),
                                         MyStruct(title: "Heat Transfer", category: "Mechanical"),
                                         MyStruct(title: "Machine Design", category: "Mechanical"),
                                         MyStruct(title: "Mechanic of Machinery", category: "Mechanical"),
                                         MyStruct(title: "Air Conditioning", category: "Mechanical"),
                                         MyStruct(title: "Electrical Machines", category: "Electrical"),
                                         MyStruct(title: "System Analysis", category: "Electrical"),
                                         MyStruct(title: "System Design", category: "Electrical"),
                                         MyStruct(title: "High Voltage Engineering", category: "Electrical"),
                                         MyStruct(title: "Electrical Instrument", category: "Electrical"),
                                         MyStruct(title: "Power Electronic", category: "Electrical"),
                                         MyStruct(title: "Power Plant Engineering", category: "Mechanical"),
                                         MyStruct(title: "Wastewater Engineering", category: "Sanitary"),
                                         MyStruct(title: "Solid Waste", category: "Sanitary"),
                                         MyStruct(title: "Water Supply Engineering", category: "Sanitary"),
                                         MyStruct(title: "Building Sanitation", category: "Sanitary")]
        
            
            for subject in allStruct {
                if subject.category.contains(topic){
                    tempData.append(.subject(info: subject))
                    finalTopic.append(subject.title)
                }
            }
            allSection.append(MySection(model: .main(info: MySect(header: topic)), items: tempData))
            sections.onNext(allSection)
            tempData.removeAll()
            allSection.removeAll()
        }
    }
    
    
    func setTopic() {
        
        let allCategory: [MyStruct] = [MyStruct(title: "General", category: "General"),
                                       MyStruct(title: "Mechanic", category: "Mechanical"),
                                       MyStruct(title: "Electrical", category: "Electrical"),
                                       MyStruct(title: "Sanitary", category: "Sanitary")]
        
        for category in allCategory {
            tempData.append(.subject(info: category))
        }
        
        sections.onNext([MySection(model: .main(info: MySect(header: "Subject")), items: tempData)])
        tempData.removeAll()
        allSection.removeAll()
        finalTopic.removeAll()
    }
}
