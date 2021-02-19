//
//  StartLessonViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 9/12/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//


import Foundation
import CardParts
import RxCocoa
import RxSwift


class StartLessonViewController: CardsViewController {
    
    var viewModel: StartLessonViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cards: [CardController] = [StartLessonController()]
        loadCards(cards: cards)
    }
}

class StartLessonController: CardPartsViewController {
    
    var viewModel: StartLessonViewModel!
    
    let startDes = CardPartTextView(type: .normal)
    let startTitle = CardPartTextView(type: .title)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoUrl = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4")  else  { return }
        
        let videoView = CardPartVideoView(videoUrl: videoUrl)
        videoView.margins = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        
        startTitle.text = "Start"
        startDes.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce fringilla magna in ipsum venenatis feugiat. Mauris varius et tortor id gravida. Vestibulum quis ultricies odio, et euismod odio. Fusce in suscipit urna. Sed ornare placerat nisi sit amet fermentum. Sed rutrum augue ac enim accumsan, pulvinar congue justo porta. Aliquam erat volutpat."
        
        setupCardParts([startTitle, startDes, videoView])
    }

}
