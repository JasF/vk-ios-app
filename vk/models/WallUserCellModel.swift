//
//  File.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc enum WallUserCellModelType: Int {
    case image
    case message
}
@objcMembers class WallUserCellModel : NSObject {
    var type:WallUserCellModelType
    var user: User?
    init(_ type:WallUserCellModelType, user: User?) {
        self.type = type
        self.user = user
    }
}
