//
//  CustomCellTableViewCell.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 29/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var subjectView: UILabel!

    var select: Bool = false
    let gradientLayer = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        subjectView.font = UIFont(name: "SukhumvitSet-Medium", size: CGFloat(20))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds }

    func setData (_ data: MyStruct) {
        subjectView.text = data.title
        
        cellView.alpha = select ? 1 : 0.5
    }
}
