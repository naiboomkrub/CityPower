//
//  CardTheme.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import Foundation
import CardParts
import UIKit

public class CardPartsBoomTheme: CardPartsTheme {
    
    public var cardsViewContentInsetTop: CGFloat = 0.0
    public var cardsLineSpacing: CGFloat = 0.0
    
    public var cardShadow: Bool = true
    public var cardCellMargins: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    public var cardPartMargins: UIEdgeInsets = UIEdgeInsets(top: 25.0, left: 5.0, bottom: 0.0, right: 5.0)
    
    // CardPartSeparatorView
    public var separatorColor: UIColor = UIColor.color(221, green: 221, blue: 221)
    public var horizontalSeparatorMargins: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)
    
    // CardPartTextView
    public var smallTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(10))!
    public var smallTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    public var normalTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
    public var normalTextColor: UIColor = UIColor.blueCity
    public var titleTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
    public var titleTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    public var headerTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(50))!
    public var headerTextColor: UIColor = UIColor.white
    public var detailTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(20))!
    public var detailTextColor: UIColor = UIColor.white
    
    // CardPartAttributedTextView
    public var smallAttributedTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(10))!
    public var smallAttributedTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    public var normalAttributedTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(12))!
    public var normalAttributedTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    public var titleAttributedTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(16))!
    public var titleAttributedTextColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    public var headerAttributedTextFont: UIFont = UIFont(name: "Baskerville-Bold", size: CGFloat(40))!
    public var headerAttributedTextColor: UIColor = UIColor.white
    public var detailAttributedTextFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(12))!
    public var detailAttributedTextColor: UIColor = UIColor.color(136, green: 136, blue: 136)
    
    // CardPartTitleView
    public var titleFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(24))!
    public var titleColor: UIColor = UIColor.blueCity
    public var titleViewMargins: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 15.0, bottom: 5.0, right: 15.0)
    
    // CardPartButtonView
    public var buttonTitleFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(18))!
    public var buttonTitleColor: UIColor = UIColor.blueCity
    public var buttonCornerRadius: CGFloat = CGFloat(10.0)
    
    // CardPartBarView
    public var barBackgroundColor: UIColor = UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0)
    public var barColor: UIColor = UIColor.turboHeaderBlueColor
    public var todayLineColor: UIColor = UIColor.Gray8
    public var barHeight: CGFloat = 13.5
    public var roundedCorners: Bool = false
    public var showTodayLine: Bool = true
    public var barCornerRadius: CGFloat? = nil
    
    // CardPartTableView
    public var tableViewMargins: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 14.0, bottom: 5.0, right: 14.0)
    
    // CardPartTableViewCell and CardPartTitleDescriptionView
    public var leftTitleFont: UIFont = UIFont(name: "SukhumvitSet-Medium", size: CGFloat(17))!
    public var leftDescriptionFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(12))!
    public var rightTitleFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(17))!
    public var rightDescriptionFont: UIFont = UIFont(name: "SukhumvitSet-Bold", size: CGFloat(12))!
    public var leftTitleColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    public var leftDescriptionColor: UIColor = UIColor.color(169, green: 169, blue: 169)
    public var rightTitleColor: UIColor = UIColor.color(17, green: 17, blue: 17)
    public var rightDescriptionColor: UIColor = UIColor.color(169, green: 169, blue: 169)
    public var secondaryTitlePosition : CardPartSecondaryTitleDescPosition = .right
    
    public init() {
        
    }
}
