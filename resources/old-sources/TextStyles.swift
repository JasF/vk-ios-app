//
//  TextStyles.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

class TextStyles : NSObject {
    static public func titleStyle () -> [NSAttributedStringKey : Any]! {
    return [ NSAttributedStringKey.foregroundColor: UIColor.black,
             NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15) ]
    }
}
