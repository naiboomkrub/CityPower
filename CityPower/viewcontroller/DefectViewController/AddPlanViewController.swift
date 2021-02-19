//
//  AddPlanViewController.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 19/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import CardParts

class AddPlanViewController: CardsViewController {
    
    var viewModel: AddPlanViewModel!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        let cards: [CardController] = []
         
        loadCards(cards: cards)
    }
}
