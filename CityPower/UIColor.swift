//
//  UIColor.swift
//  korwor
//
//  Created by Natcha Watcharawittayakul on 25/8/2563 BE.
//  Copyright © 2563 City Power. All rights reserved.
//
import UIKit

extension UIColor {
    
    static var turboGenericGreyTextColor : UIColor {get{return UIColor.color(169, green: 169, blue: 169)}}
    static var turboCardPartTitleColor : UIColor {get{return UIColor.color(17, green: 17, blue: 17)}}
    static var turboCardPartTextColor : UIColor {get{return UIColor.color(136, green: 136, blue: 136)}}
    static var cardPartAttributedTextColor : UIColor {get{return UIColor.color(0, green: 0, blue: 255)}}

    static var turboSeperatorColor : UIColor {get{return UIColor.color(221, green: 221, blue: 221)}}
    static var turboBlueColor : UIColor {get{return UIColor(red: 69.0/255.0, green: 202.0/255.0, blue: 230.0/255.0, alpha: 1.0)}}
    static var turboHeaderBlueColor: UIColor { get { return UIColor.colorFromHex(0x05A4B5) }}
    static var turboGreenColor : UIColor {get{return UIColor(red: 10.0/255.0, green: 199.0/255.0, blue: 117.0/255.0, alpha: 1.0)}}
    static var turboSeperatorGray : UIColor {get{return UIColor(red: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0)}}
    static var Black : UIColor {get{return UIColor.colorFromHex(0x000000)}}
    static var Gray0 : UIColor {get{return UIColor.colorFromHex(0x333333)}}
    static var Gray1 : UIColor {get{return UIColor.colorFromHex(0x666666)}}
    static var Gray2 : UIColor {get{return UIColor.colorFromHex(0x999999)}}
    static var Gray3 : UIColor {get{return UIColor.colorFromHex(0xCCCCCC)}}
    static var Gray4 : UIColor {get{return UIColor.colorFromHex(0xDDDDDD)}}
    static var Gray5 : UIColor {get{return UIColor.colorFromHex(0xF0F0F0)}}
    static var Gray6 : UIColor {get{return UIColor.colorFromHex(0xF5F5F5)}}
    static var Gray7 : UIColor {get{return UIColor.colorFromHex(0xE7E7E7)}}
    static var Gray8 : UIColor {get{return UIColor.colorFromHex(0xB2B2B2)}}
    
    static var lavender : UIColor {get{return UIColor(red:204/255, green:102/255, blue:255/255, alpha:1.0)}}
    static var aqua : UIColor {get{return UIColor(red:0/255, green:128/255, blue:255/255, alpha:1.0)}}
    
    static var blue1 : UIColor {get{return UIColor.colorFromHex(0x4567C4)}}
    static var blueCity : UIColor {get{return UIColor.colorFromHex(0x2B318B)}}
    static var lightBlueCity : UIColor {get{return UIColor.colorFromHex(0x26A9E0)}}
    static var whiteCity: UIColor {get{return UIColor.colorFromHex(0x8ED0FF)}}
    static var bottomBar1: UIColor {get{return UIColor.colorFromHex(0x0096E3)}}
    static var bottomBar2: UIColor {get{return UIColor.colorFromHex(0x26DBDD)}}
    static var choice1: UIColor {get{return UIColor.colorFromHex(0x0095E2)}}
    static var start1: UIColor {get{return UIColor.colorFromHex(0x2B318B)}}
    static var start2: UIColor {get{return UIColor.colorFromHex(0x00055A)}}
    static var border: UIColor {get{return UIColor.colorFromHex(0x0094E1)}}
    static var com1: UIColor {get{return UIColor.colorFromHex(0xF8AD40)}}
    static var com2: UIColor {get{return UIColor.colorFromHex(0xEF7013)}}
    static var correct: UIColor {get{return UIColor.colorFromHex(0x28DCDC)}}
    static var wrong: UIColor {get{return UIColor.colorFromHex(0xFF2515)}}
    
    static var general: UIColor {get{return UIColor.colorFromHex(0x808080)}}
    static var general2: UIColor {get{return UIColor.colorFromHex(0xB6B8BA)}}
    static var electrical: UIColor {get{return UIColor.colorFromHex(0xEC7013)}}
    static var electrical2: UIColor {get{return UIColor.colorFromHex(0xF5AA40)}}
    static var mechincal: UIColor {get{return UIColor.colorFromHex(0x16003F)}}
    static var mechincal2: UIColor {get{return UIColor.colorFromHex(0x2B318B)}}
    static var sanitary: UIColor {get{return UIColor.colorFromHex(0x0092DF)}}
    static var sanitary2: UIColor {get{return UIColor.colorFromHex(0x28DCDC)}}
    
    static var shadow: UIColor {get{return UIColor.colorFromHex(0xADB4D4)}}

    class func color(_ red: Int, green: Int, blue: Int) -> UIColor {
        return UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
    
    static func colorFromHex(_ rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
    
    //Confetti Colors
    public static var flushOrange : UIColor {get{return UIColor.colorFromHex(0xFF8000)}}
    public static var eggBlue : UIColor {get{return UIColor.colorFromHex(0x07C4D9)}}
    public static var blushPink: UIColor {get{return UIColor.colorFromHex(0xFF88EC)}}
    public static var cerulean: UIColor {get{return UIColor.colorFromHex(0x0097E6)}}
    public static var limeGreen: UIColor {get{return UIColor.colorFromHex(0x53B700)}}
    public static var yellowSea: UIColor {get{return UIColor.colorFromHex(0xFFAD00)}}
    public static var superNova: UIColor {get{return UIColor.colorFromHex(0xFFCA00)}}
    public static var darkred: UIColor {get{return UIColor.colorFromHex(0xD01C1C)}}
}
