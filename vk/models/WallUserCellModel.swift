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
    case actions
    case avatarNameDate
}
@objcMembers class WallUserCellModel : NSObject {
    var type:WallUserCellModelType
    var user: User?
    var date: Int = 0
    init(_ type:WallUserCellModelType, user: User?) {
        self.type = type
        self.user = user
        super.init()
    }
    init(_ type:WallUserCellModelType, user: User?, date: Int) {
        self.type = type
        self.user = user
        self.date = date
    }
}
