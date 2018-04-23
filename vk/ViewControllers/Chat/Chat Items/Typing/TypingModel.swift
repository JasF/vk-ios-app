//
//  TypingModel.swift
//  vk
//
//  Created by Jasf on 21.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import UIKit
import Chatto

class TypingModel: ChatItemProtocol {
    let uid: String
    let type: String = TypingModel.chatItemType
    
    static var chatItemType: ChatItemType {
        return "TypingModel"
    }
    
    init(uid: String) {
        self.uid = uid
    }
}
