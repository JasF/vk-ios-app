//
//  TextStyles.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

class TextStyles {
    static public func eulaTextStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.black,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14) ]
    }
    static public func nameStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.black,
                 NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 15) ]
    }
    static public func titleStyle() -> [NSAttributedStringKey : Any]! {
    return [ NSAttributedStringKey.foregroundColor: UIColor.black,
             NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    
    static public func titleLightStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.black,
                 NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: 15) ]
    }
    
    static public func postLinkStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor(red: 59.0/255.0, green: 89.0/255.0, blue: 152.0/255.0, alpha: 1.0),
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15),
                 NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle
            ]
    }
    
    static public func authorizationButtonStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor(red: 10.0/255.0, green: 43.0/255.0, blue: 57.0/255.0, alpha: 1.0),
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14),
        ]
    }
    
    static public func eulaButtonStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.white,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)
            , .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
            //, NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle
        ]
    }
    static public func eulaHighlightedButtonStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.white.withAlphaComponent(0.5),
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)
            , .underlineStyle: NSUnderlineStyle.styleSingle.rawValue
            //, NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle
        ]
    }
    
    /*
    + (NSDictionary *)postLinkStyle
    {
    return @{
    NSFontAttributeName : [UIFont systemFontOfSize:15.0],
    NSForegroundColorAttributeName: [UIColor colorWithRed:59.0/255.0 green:89.0/255.0 blue:152.0/255.0 alpha:1.0],
    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    }
    */
    static public func buttonStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.blue,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
    static public func createPostStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.black,
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 25) ]
    }
    static public func createPostTextColor() -> UIColor { return UIColor.black }
    static public func createPostFont() -> UIFont { return UIFont.systemFont(ofSize: 25) }
    static public func createPostPlaceholderStyle() -> [NSAttributedStringKey : Any]! {
        return [ NSAttributedStringKey.foregroundColor: UIColor.black.withAlphaComponent(0.4),
                 NSAttributedStringKey.font: UIFont.systemFont(ofSize: 25) ]
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
