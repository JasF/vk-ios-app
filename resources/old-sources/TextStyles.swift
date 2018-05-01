//
//  TextStyles.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

class TextStyles {
    static public func nameStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.black,
                 NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15) ]
    }
    static public func titleStyle() -> [NSAttributedStringKey : Any]! {
    return [ NSAttributedStringKey.foregroundColor: UIColor.black,
             NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    static public func buttonStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.blue,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    static public func usernameGradientStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.white,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    static public func timeStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.gray,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13) ]
    }
    static public func buttonTextStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.white,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    static public func buttonPassiveTextStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.init(red: 60.0/255, green: 60.0/255, blue: 60.0/255, alpha: 1.0),
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    static public func buttonColor() -> UIColor {
        return UIColor.init(red: 70.0/255, green: 120.0/255, blue: 177.0/255, alpha: 1.0)
    }
    static public func buttonPassiveColor() -> UIColor {
        return UIColor.init(red: 200.0/255, green: 200.0/255, blue: 200.0/255, alpha: 1.0)
    }
}
